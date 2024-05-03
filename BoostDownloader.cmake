# - Find Boost
# 
# Based on https://gist.github.com/thiagowfx/970e3931387ed7db9a39709a8a130ee9 Copyright (c) 2016 Thiago Barroso Perrotta
#
# Permission is hereby granted, free of charge, to any person obtaining a copy of
# this software and associated documentation files (the "Software"), to deal in
# the Software without restriction, including without limitation the rights to
# use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
# the Software, and to permit persons to whom the Software is furnished to do so,
# subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
# FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
# COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
# IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
# CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

if(NOT BOOST_BUILD_COMPONENTS)
	message(FATAL_ERROR "No COMPONENTS specified for Boost")
endif()

# Create a list(string) for the build command (e.g. --with-program_options;--with-system)
# and assigns it to BOOST_COMPONENTS_FOR_BUILD
foreach(component ${BOOST_BUILD_COMPONENTS})
	list(APPEND BOOST_COMPONENTS_FOR_BUILD --with-${component})
endforeach()

macro(DO_FIND_BOOST_DOWNLOAD)
	if(NOT BOOST_REQUESTED_VERSION)
		message(FATAL_ERROR "BOOST_REQUESTED_VERSION is not defined.")
	endif()

	string(REPLACE "." "_" BOOST_REQUESTED_VERSION_UNDERSCORE ${BOOST_REQUESTED_VERSION})

	set(BOOST_MAYBE_STATIC)
	if(BOOST_USE_STATIC_LIBS)
		set(BOOST_MAYBE_STATIC "link=static")
	endif()

	include(ExternalProject)
	if(WIN32)
	ExternalProject_Add(
		Boost
		URL https://boostorg.jfrog.io/artifactory/main/release/${BOOST_REQUESTED_VERSION}/source/boost_${BOOST_REQUESTED_VERSION_UNDERSCORE}.7z
		# URL https://downloads.sourceforge.net/project/boost/boost/${BOOST_REQUESTED_VERSION}/boost_${BOOST_REQUESTED_VERSION_UNDERSCORE}.zip
		UPDATE_COMMAND ""
		CONFIGURE_COMMAND ./bootstrap.bat --prefix=${BOOST_ROOT_DIR}
		BUILD_COMMAND ./b2 ${BOOST_MAYBE_STATIC} --prefix=${BOOST_ROOT_DIR} ${BOOST_COMPONENTS_FOR_BUILD} install
		BUILD_IN_SOURCE true
		INSTALL_COMMAND ""
		INSTALL_DIR ${BOOST_ROOT_DIR}
		)
	else()
	ExternalProject_Add(
		Boost
		URL https://boostorg.jfrog.io/artifactory/main/release/${BOOST_REQUESTED_VERSION}/source/boost_${BOOST_REQUESTED_VERSION_UNDERSCORE}.tar.gz
		# URL https://downloads.sourceforge.net/project/boost/boost/${BOOST_REQUESTED_VERSION}/boost_${BOOST_REQUESTED_VERSION_UNDERSCORE}.zip
		UPDATE_COMMAND ""
		CONFIGURE_COMMAND ./bootstrap.sh --prefix=${BOOST_ROOT_DIR}
		BUILD_COMMAND ./b2 ${BOOST_MAYBE_STATIC} --prefix=${BOOST_ROOT_DIR} ${BOOST_COMPONENTS_FOR_BUILD} install
		BUILD_IN_SOURCE true
		INSTALL_COMMAND ""
		INSTALL_DIR ${BOOST_ROOT_DIR}
	)
	endif()

	ExternalProject_Get_Property(Boost install_dir)
endmacro()

DO_FIND_BOOST_DOWNLOAD()
