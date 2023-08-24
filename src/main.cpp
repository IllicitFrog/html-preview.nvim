#include "server.hpp"
#include "boost/program_options.hpp"
#include "boost/program_options/parsers.hpp"
#include "boost/program_options/positional_options.hpp"
#include <iostream>
#include <string>

#define Default_Port 8090

int main(int argc, char *argv[]) {
  try {
    boost::program_options::options_description desc("Allowed options");
    // clang-format off
    desc.add_options()
      ( "help,h", "Print Help\n")
      ( "rootdir,r", boost::program_options::value<std::string>()->default_value(" "), "Root Directory of project(Required) \n   -absolute path required\n   -all paths are relative from here\n")
      ( "address,a", boost::program_options::value<std::string>()->default_value("0.0.0.0"), "Set server address, defaults to 0.0.0.0\n")
      ( "port,p", boost::program_options::value<unsigned short>()->default_value(Default_Port), "Port, defaults to 8089\n")
      ( "index, i", boost::program_options::value<std::string>()->default_value("index.html"), "Default html page to launch from host \n   -relative to root directory \n   -loads on: http://localhost:8089/\n")
      ( "mustache,m", boost::program_options::value<std::string>()->default_value(" "), "Json file for mustache templating \n   -absolute path required \n   - eg /home/user/myproject/mustache.json\n")
      ( "livejs,j", boost::program_options::bool_switch(), "Disable LiveJS")
      ;
    // clang-format on
    boost::program_options::variables_map povm;
    boost::program_options::store(
        boost::program_options::parse_command_line(argc, argv, desc), povm);
    boost::program_options::notify(povm);

    if (povm.count("help") != 0U) {
      std::cout << "--LiveWebPreview--" << std::endl;
      std::cout << "(Made for usage with Neovim plug Neo_WebPreview)"
                << std::endl;
      std::cout << "Usage:" << std::endl
                << " nbj --rootdir /home/user/myproject/ --mustasche "
                   "/home/user/myproject/presets.json"
                << std::endl
                << std::endl;
      std::cout << desc << std::endl;
      return -1;
    }

    if (povm["rootdir"].as<std::string>() == " ") {
      std::cout << std::endl
                << "Working directory required! nph --rootdir "
                   "/*absolute path*/"
                << std::endl;
      return -1;
    }

    server syncserv(
        povm["rootdir"].as<std::string>(), povm["port"].as<unsigned short>(),
        povm["mustache"].as<std::string>(), povm["livejs"].as<bool>(),
        povm["address"].as<std::string>(), povm["index"].as<std::string>());

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
