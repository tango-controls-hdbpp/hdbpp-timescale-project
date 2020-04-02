# Functions and Pre-build  -----------------------------------

# Stop messy in source builds
set(CMAKE_DISABLE_IN_SOURCE_BUILD ON)
set(CMAKE_DISABLE_SOURCE_CHANGES  ON)

if ( ${CMAKE_SOURCE_DIR} STREQUAL ${CMAKE_BINARY_DIR} )
    message( FATAL_ERROR "In-source builds not allowed. Please make a new directory (called a build directory) and run CMake from there. You may need to remove CMakeCache.txt." )
endif()

# Start Build Config -----------------------------------
cmake_minimum_required(VERSION 3.11)
set(CMAKE_SKIP_RPATH true)
set(CMAKE_VERBOSE_MAKEFILE ON)
set(CMAKE_COLOR_MAKEFILE ON)

# Start the project
project(hdbpp-timescale-project)

# Build options
option(BYPASS_LIBHDBPP "Link device servers directly tothe libhdbpp-timescale backend" OFF)
option(STATIC_LINK_DEVICE_SERVERS "Statically link the device servers to the libraries (simplifies deployment)" OFF)

if(BYPASS_LIBHDBPP)
    if(STATIC_LINK_DEVICE_SERVERS)
        set(BACKEND_LIBRARY_TARGET "libhdbpp_timescale_static_library")
        message(STATUS "Set to bypass libhdbpp and link libhdbpp-timescale statically")
    else()
        set(BACKEND_LIBRARY_TARGET "libhdbpp_timescale_shared_library")
        message(STATUS "Set to bypass libhdbpp and link libhdbpp-timescale as a shared object")
    endif()
else()
    list(APPEND BACKEND_LIBRARY_TARGET "libhdbpp_shared_library")
endif()

# flags that take effect in the sub-components, this will configure 
# the hdbpp_es/hdbpp_cm to link to the libhdbpp CMake target rather than
# the actual library, this is better since it forces them to link to the version
# produced here, and test against it if they are run from the build folder
set(LIBHDBPP_PROJECT_BUILD TRUE)

# component versions that will be pulled on building. This can be a commit number, a branch name or a tag.
set(HDBPP_ES_VERSION "integrated-build")
set(HDBPP_CM_VERSION "integrated-build")
set(LIBHDBPP_VERSION "exp-refactor")
set(LIBHDBPP_TIMESCALE_VERSION "project-build2")

set(EXTERNAL_PROJECT_DIR "external")
set(DOWNLOAD_DIR "download")

# this will enable clang on all sub-compoents
option(ENABLE_CLANG "Enable clang code and layout analysis" OFF)

# Code Analysis -----------------------------------
if(ENABLE_CLANG)
    set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

    # To find clang, find_program will search your PATH environment variable.
    # Ensure if you have a non-standard clang install, that it has been added
    # to your path.
    find_program(CLANG_TIDY_EXE 
        NAMES "clang-tidy" 
        DOC "Path to clang-tidy executable")

    if(NOT CLANG_TIDY_EXE)
        message(STATUS "clang-tidy not found.")
    else(NOT CLANG_TIDY_EXE)
        message(STATUS "clang-tidy found: ${CLANG_TIDY_EXE}")
        set(DO_CLANG_TIDY "${CLANG_TIDY_EXE}")
    endif(NOT CLANG_TIDY_EXE)
endif(ENABLE_CLANG)

# Find Dependencies  ---------------------
add_subdirectory(components/hdbpp-health-check EXCLUDE_FROM_ALL)

include(FetchContent)
set(FETCHCONTENT_QUIET off)

FetchContent_Declare(
    hdbpp_cm
    GIT_REPOSITORY "https://github.com/tango-controls-hdbpp/hdbpp-cm.git" 
    GIT_TAG ${HDBPP_ES_VERSION}
    SOURCE_DIR "${CMAKE_SOURCE_DIR}/${EXTERNAL_PROJECT_DIR}/hdbpp_cm")

FetchContent_GetProperties(hdbpp_cm)

if(NOT hdbpp_cm_POPULATED)
    FetchContent_Populate(hdbpp_cm)
    add_subdirectory(${hdbpp_cm_SOURCE_DIR} ${hdbpp_cm_BINARY_DIR} EXCLUDE_FROM_ALL)
endif()

FetchContent_Declare(
    hdbpp_es
    GIT_REPOSITORY "https://github.com/tango-controls-hdbpp/hdbpp-es.git" 
    GIT_TAG ${HDBPP_ES_VERSION}
    SOURCE_DIR "${CMAKE_SOURCE_DIR}/${EXTERNAL_PROJECT_DIR}/hdbpp_es")

FetchContent_GetProperties(hdbpp_es)

if(NOT hdbpp_es_POPULATED)
    FetchContent_Populate(hdbpp_es)
    add_subdirectory(${hdbpp_es_SOURCE_DIR} ${hdbpp_es_BINARY_DIR} EXCLUDE_FROM_ALL)
endif()

if(NOT BYPASS_LIBHDBPP)
    FetchContent_Declare(
        libhdbpp
        GIT_REPOSITORY "https://github.com/tango-controls-hdbpp/libhdbpp.git" 
        GIT_TAG ${LIBHDBPP_VERSION}
        SOURCE_DIR "${CMAKE_SOURCE_DIR}/${EXTERNAL_PROJECT_DIR}/libhdbpp")

    FetchContent_GetProperties(libhdbpp)

    if(NOT libhdbpp_POPULATED)
        FetchContent_Populate(libhdbpp)
        add_subdirectory(${libhdbpp_SOURCE_DIR} ${libhdbpp_BINARY_DIR} EXCLUDE_FROM_ALL)
    endif()
endif()

FetchContent_Declare(
    libhdbpp_timescale
    GIT_REPOSITORY "https://github.com/tango-controls-hdbpp/libhdbpp-timescale.git" 
    GIT_TAG ${LIBHDBPP_TIMESCALE_VERSION}
    SOURCE_DIR "${CMAKE_SOURCE_DIR}/${EXTERNAL_PROJECT_DIR}/libhdbpp-timescale")

FetchContent_GetProperties(libhdbpp_timescale)

if(NOT libhdbpp_timescale_POPULATED)
    FetchContent_Populate(libhdbpp_timescale)
    add_subdirectory(${libhdbpp_timescale_SOURCE_DIR} ${libhdbpp_timescale_BINARY_DIR} EXCLUDE_FROM_ALL)
endif()

# Redirect all binary artifacts to the build directory, to simplify testing

if(NOT BYPASS_LIBHDBPP)
    set_target_properties(libhdbpp_shared_library
        PROPERTIES
            ARCHIVE_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}"
            RUNTIME_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}"
            LIBRARY_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}")
endif()

set_target_properties(hdbpp_es
    PROPERTIES
        ARCHIVE_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}"
        RUNTIME_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}"
        LIBRARY_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}")

set_target_properties(hdbpp_cm
    PROPERTIES
        ARCHIVE_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}"
        RUNTIME_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}"
        LIBRARY_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}")

set_target_properties(hdbpp_health_check
    PROPERTIES
        ARCHIVE_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}"
        RUNTIME_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}"
        LIBRARY_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}")

set_target_properties(libhdbpp_timescale_shared_library
    PROPERTIES
        ARCHIVE_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}"
        RUNTIME_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}"
        LIBRARY_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}")

set_target_properties(libhdbpp_timescale_static_library
    PROPERTIES
        ARCHIVE_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}"
        RUNTIME_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}"
        LIBRARY_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}")

# now create a phoney target that can build the entire project
add_custom_target(project)

add_dependencies(project 
    ${BACKEND_LIBRARY_TARGET}
    hdbpp_es 
    hdbpp_cm 
    hdbpp_health_check)

set_target_properties(project
    PROPERTIES
        RUNTIME_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}")
