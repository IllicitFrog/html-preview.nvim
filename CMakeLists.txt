cmake_minimum_required(VERSION 3.10)

project(neoweb_preview)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

list(APPEND CMAKE_MODULE_PATH ${CMAKE_SOURCE_DIR})

set(BOOST_ROOT_DIR ${CMAKE_SOURCE_DIR}/external/boost)
set(BOOST_BUILD_COMPONENTS thread url filesystem)

set(Boost_hardcoded_INCLUDE_DIRS ${BOOST_ROOT_DIR}/include)
foreach(component ${BOOST_BUILD_COMPONENTS})
	list(APPEND Boost_hardcoded_libraries ${BOOST_ROOT_DIR}/lib/libboost_${component}.so)
endforeach()

set(BOOST_ROOT ${BOOST_ROOT_DIR})

find_package(PkgConfig REQUIRED)
find_package(Lua REQUIRED)
find_package(Boost 1.80.0 COMPONENTS ${BOOST_BUILD_COMPONENTS})


message(STATUS ${Boost_hardcoded_libraries})
message(STATUS ${Boost_INCLUDE_DIRS})
message(STATUS ${Boost_FOUND})

add_library(${PROJECT_NAME} SHARED src/nwp.cpp)

if(Boost_FOUND)
    set(BOOST_REQUESTED_VERSION 1.80.0)
    message(WARNING "Boost library NOT found, download boost-${BOOST_REQUESTED_VERSION} and build from boost website.")
    include(BoostDownloader.cmake)
    add_custom_target(ExternalProject_Boost
        DEPENDS Boost
    )
    add_dependencies(${PROJECT_NAME} ExternalProject_Boost)
endif()

target_include_directories(${PROJECT_NAME} PUBLIC ${Boost_hardcoded_INCLUDE_DIRS} ${CMAKE_HOME_DIRECTORY}/include)
target_link_libraries(${PROJECT_NAME} PUBLIC ${LUA_LIBRARIES} ${Boost_hardcoded_libraries})
