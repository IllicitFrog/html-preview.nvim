#pragma once
#include "boost/beast/http/string_body.hpp"
#include "boost/url/urls.hpp"
#include "livejs.hpp"
#include "utils.hpp"
#include <boost/algorithm/string/replace.hpp>
#include <fstream>
#include <inja/inja.hpp>
#include <iostream>
#include <nlohmann/json.hpp>
#include <stdexcept>
#include <string>
#include <thread>
#include <utility>

namespace beast = boost::beast;
namespace http = beast::http;
namespace net = boost::asio;

using tcp = boost::asio::ip::tcp;
constexpr unsigned short Default_Port = 8090;

class server {
public:
  server();
  explicit server(std::string doc_root_, unsigned short port_ = Default_Port,
         std::string index_ = "index.html")
      : acceptor{ioc, {net::ip::make_address("0.0.0.0"), port_}},
        doc_root(std::move(doc_root_)), index(std::move(index_)) {}

  void run() {
    while (active) {
      tcp::socket socket(ioc);
      acceptor.accept(socket);
      std::thread{&server::do_session, this, std::move(socket)}.detach();
    }
  }

  void loadMustache(std::string json) {
    mustache_values = nlohmann::json::parse(json);
    mustache = true;
  }

  void unloadMustache() { mustache = false; }

private:
  std::string doc_root;
  std::string index;
  net::io_context ioc{1};
  tcp::acceptor acceptor;
  nlohmann::json mustache_values;
  bool mustache{};
  bool disableljs{};
  bool active{true};

  // Return a response for the given request.
  //
  // The concrete type of the response message (which depends on the
  // request), is type-erased in message_generator.
  template <class Body, class Allocator>
  http::message_generator
  handle_request(beast::string_view doc_root,
                 http::request<Body, http::basic_fields<Allocator>> &&req) {
    // Returns a bad request response
    auto const bad_request = [&req](beast::string_view why) {
      http::response<http::string_body> res{http::status::bad_request,
                                            req.version()};
      res.set(http::field::server, BOOST_BEAST_VERSION_STRING);
      res.set(http::field::content_type, "text/html");
      res.keep_alive(req.keep_alive());
      res.body() = std::string(why);
      res.prepare_payload();
      return res;
    };

    // Returns a not found response
    auto const not_found = [&req](beast::string_view target) {
      http::response<http::string_body> res{http::status::not_found,
                                            req.version()};
      res.set(http::field::server, BOOST_BEAST_VERSION_STRING);
      res.set(http::field::content_type, "text/html");
      res.keep_alive(req.keep_alive());
      res.body() = "The resource '" + std::string(target) + "' was not found.";
      res.prepare_payload();
      return res;
    };

    // Returns a server error response
    auto const server_error = [&req](beast::string_view what) {
      http::response<http::string_body> res{http::status::internal_server_error,
                                            req.version()};
      res.set(http::field::server, BOOST_BEAST_VERSION_STRING);
      res.set(http::field::content_type, "text/html");
      res.keep_alive(req.keep_alive());
      res.body() = "An error occurred: '" + std::string(what) + "'";
      res.prepare_payload();
      return res;
    };

    // Make sure we can handle the method
    if (req.method() != http::verb::get && req.method() != http::verb::head) {
      return bad_request("Unknown HTTP-method");
    }

    // Request path must be absolute and not contain "..".
    if (req.target().empty() || req.target()[0] != '/' ||
        req.target().find("..") != beast::string_view::npos) {
      return bad_request("Illegal request-target");
    }

    std::string reqUrl = req.target();

    // Remove any get params
    if (boost::url_view(reqUrl).has_query()) {
      reqUrl = boost::url(reqUrl).remove_query().remove_fragment().c_str();
    }

    // Build the path to the requested file
    std::string path = path_cat(doc_root, reqUrl);
    if (req.target().back() == '/') {
      path.append(index);
    }

    beast::string_view mime = mime_type(path);

    // If its an HTML request append LiveJS to it
    if (mime == "text/html") {
      http::response<http::string_body> res{http::status::ok, req.version()};
      res.set(http::field::server, BOOST_BEAST_VERSION_STRING);
      res.set(http::field::content_type, mime);

      std::ifstream file(path, std::ios_base::in);
      if (file.good()) {
        std::string body = {std::istreambuf_iterator<char>(file),
                            std::istreambuf_iterator<char>()};
        if (mustache) {
          body = inja::render(body, mustache_values);
        }
        if (!disableljs) {
          boost::replace_all(body, "<head>", retLivejs());
        }
        res.content_length(body.size());
        res.body() = std::move(body);
        res.keep_alive(req.keep_alive());
        return res;
      }
      return not_found(reqUrl);
    }

    // Attempt to open the file
    beast::error_code error_code;
    http::file_body::value_type body;
    body.open(path.c_str(), beast::file_mode::scan, error_code);

    // Handle the case where the file doesn't exist
    if (error_code == beast::errc::no_such_file_or_directory) {
      return not_found(reqUrl);
    }

    // Handle an unknown error
    if (error_code) {
      return server_error(error_code.message());
    }

    // Cache the size since we need it after the move
    auto const size = body.size();

    // Respond to HEAD request
    if (req.method() == http::verb::head) {
      http::response<http::empty_body> res{http::status::ok, req.version()};
      res.set(http::field::server, BOOST_BEAST_VERSION_STRING);
      res.set(http::field::content_type, mime);
      res.content_length(size);
      res.keep_alive(req.keep_alive());
      return res;
    }

    // Respond to GET request
    http::response<http::file_body> res{
        std::piecewise_construct, std::make_tuple(std::move(body)),
        std::make_tuple(http::status::ok, req.version())};
    res.set(http::field::server, BOOST_BEAST_VERSION_STRING);
    res.set(http::field::content_type, mime);
    res.content_length(size);
    res.keep_alive(req.keep_alive());
    return res;
  }

  // Handles an HTTP server connection
  void do_session(tcp::socket socket) {
    beast::error_code error_code;

    // This buffer is required to persist across reads
    beast::flat_buffer buffer;

    for (;;) {
      // Read a request
      http::request<http::string_body> req;
      http::read(socket, buffer, req, error_code);
      if (error_code == http::error::end_of_stream) {
        break;
      }
      if (error_code) {
        return fail(error_code, "read");
      }

      // Handle request
      http::message_generator msg = handle_request(doc_root, std::move(req));

      // Determine if we should close the connection
      bool keep_alive = msg.keep_alive();

      // Send the response
      beast::write(socket, std::move(msg), error_code);

      if (error_code) {
        return fail(error_code, "write");
      }
      if (!keep_alive) {
        // This means we should close the connection, usually because
        // the response indicated the "Connection: close" semantic.
        break;
      }
    }

    // Send a TCP shutdown
    socket.shutdown(tcp::socket::shutdown_send, error_code);

    // At this point the connection is closed gracefully
  }
  //------------------------------------------------------------------------------

  // Report a failure
  static void fail(beast::error_code error_code, char const *what) {
    std::cerr << what << ": " << error_code.message() << "\n";
  }
};
