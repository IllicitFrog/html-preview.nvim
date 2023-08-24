cmake_minimum_required(VERSION 3.10)

project(neoweb_preview)

set(Boost_USE_MULTITHREADED      ON)
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/bin)
set(CMAKE_ARCHIVE_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/bin)
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

find_package(Boost 1.81.0 REQUIRED COMPONENTS thread system url filesystem date_time program_options )
add_executable(${PROJECT_NAME} src/main.cpp)

target_link_libraries(${PROJECT_NAME} ${Boost_LIBRARIES})
include_directories(${CMAKE_HOME_DIRECTORY}/include ${Boost_INCLUDE_DIRS})
