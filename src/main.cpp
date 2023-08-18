#include <boost/asio/ip/address.hpp>
#include <boost/asio/ip/tcp.hpp>
#include <boost/program_options.hpp>
#include <boost/program_options/parsers.hpp>
#include <boost/program_options/positional_options.hpp>
#include <cstdlib>
#include <filesystem>
#include <iostream>
#include <memory>
#include <string>
#include <thread>
#include <vector>

#include "server.hpp"

using tcp = boost::asio::ip::tcp;

int main(int argc, char *argv[]) {
  try {
    boost::program_options::options_description desc("Allowed options");
    // clang-format off
    desc.add_options()
      ( "help", "Print Help")
      ( "port,p", boost::program_options::value<unsigned short>()->required(), "Port (If blank assigned randomly)")
      ( "rootdir,r", boost::program_options::value<std::string>()->required(), "Root Directory -- ie ~/workspace/myproject/")
      ;
    // clang-format on
    boost::program_options::variables_map povm;
    boost::program_options::store(
        boost::program_options::parse_command_line(argc, argv, desc), povm);
    boost::program_options::notify(povm);

    if (povm.count("help") != 0U) {
      std::cout << desc << std::endl;
      return -1;
    }
    server syncserv(povm["port"].as<unsigned short>(), povm["rootdir"].as<std::string>());
    while (true) {
      syncserv.run();
    }

  } catch (std::exception &e) {
    std::cerr << "error: " << e.what() << "\n";
    return EXIT_FAILURE;
  } catch (...) {
    std::cerr << "Exception of unknown type!\n";
  }
  return 0;
}
