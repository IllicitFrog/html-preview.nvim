cmake_minimum_required(VERSION 3.24)

project(neoweb_preview)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

find_package(PkgConfig REQUIRED)
find_package(Lua REQUIRED)
find_package(Boost REQUIRED COMPONENTS filesystem url thread)

add_library(${PROJECT_NAME} SHARED src/nwp.cpp)

target_link_libraries(${PROJECT_NAME} PUBLIC ${LUA_LIBRARIES} ${Boost_LIBRARIES})
include_directories(${CMAKE_HOME_DIRECTORY}/include)

