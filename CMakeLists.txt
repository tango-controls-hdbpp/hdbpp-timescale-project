# Functions and Pre-build  -----------------------------------

# Stop messy in source builds
set(CMAKE_DISABLE_IN_SOURCE_BUILD ON)
set(CMAKE_DISABLE_SOURCE_CHANGES  ON)

if ( ${CMAKE_SOURCE_DIR} STREQUAL ${CMAKE_BINARY_DIR} )
    message( FATAL_ERROR "In-source builds not allowed. Please make a new directory (called a build directory) and run CMake from there. You may need to remove CMakeCache.txt." )
endif()

# Start Build Config -----------------------------------
cmake_minimum_required(VERSION 3.6)
set(CMAKE_SKIP_RPATH true)
set(CMAKE_VERBOSE_MAKEFILE ON)
set(CMAKE_COLOR_MAKEFILE ON)

# Start the project
project(hdbpp-timescale-project)

# flags that take effect in the sub-components, this will configure 
# the hdbpp_es/hdbpp_cm to link to the libhdbpp CMake target rather than
# the actual library, this is better since it forces them to link to the version
# produced here, and test against it if they are run from the build folder
set(LIBHDBPP_PROJECT_BUILD TRUE)

# component versions that will be pulled on building
set(HDBPP_ES_VERSION "integrated-build")
set(HDBPP_CM_VERSION "integrated-build")
set(LIBHDBPP_VERSION "exp-refactor")
set(EXTERNAL_PROJECT_DIR "components/external")
set(DOWNLOAD_DIR "download")

# this will enable clang on all sub-compoents
option(ENABLE_CLANG "Enable clang code and layout analysis" ON)

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

# configure hdbpp-es
configure_file(
    ${CMAKE_CURRENT_SOURCE_DIR}/cmake/Fetch-hdbpp-es.cmake.in 
    ${CMAKE_BINARY_DIR}/hdbpp-es-${DOWNLOAD_DIR}/CMakeLists.txt)

execute_process(COMMAND "${CMAKE_COMMAND}" -G "${CMAKE_GENERATOR}" . WORKING_DIRECTORY "${CMAKE_BINARY_DIR}/hdbpp-es-${DOWNLOAD_DIR}" )
execute_process(COMMAND "${CMAKE_COMMAND}" --build . WORKING_DIRECTORY "${CMAKE_BINARY_DIR}/hdbpp-es-${DOWNLOAD_DIR}" )

# configure hdbpp-cm
configure_file(
    ${CMAKE_CURRENT_SOURCE_DIR}/cmake/Fetch-hdbpp-cm.cmake.in 
    ${CMAKE_BINARY_DIR}/hdbpp-cm-${DOWNLOAD_DIR}/CMakeLists.txt)

execute_process(COMMAND "${CMAKE_COMMAND}" -G "${CMAKE_GENERATOR}" . WORKING_DIRECTORY "${CMAKE_BINARY_DIR}/hdbpp-cm-${DOWNLOAD_DIR}" )
execute_process(COMMAND "${CMAKE_COMMAND}" --build . WORKING_DIRECTORY "${CMAKE_BINARY_DIR}/hdbpp-cm-${DOWNLOAD_DIR}" )

# configure libhdbpp
configure_file(
    ${CMAKE_CURRENT_SOURCE_DIR}/cmake/Fetch-libhdbpp.cmake.in 
    ${CMAKE_BINARY_DIR}/libhdbpp-${DOWNLOAD_DIR}/CMakeLists.txt)
    
execute_process(COMMAND "${CMAKE_COMMAND}" -G "${CMAKE_GENERATOR}" . WORKING_DIRECTORY "${CMAKE_BINARY_DIR}/libhdbpp-${DOWNLOAD_DIR}" )
execute_process(COMMAND "${CMAKE_COMMAND}" --build . WORKING_DIRECTORY "${CMAKE_BINARY_DIR}/libhdbpp-${DOWNLOAD_DIR}" )

# add the various components to the project
add_subdirectory(${EXTERNAL_PROJECT_DIR}/hdbpp-es EXCLUDE_FROM_ALL)
add_subdirectory(${EXTERNAL_PROJECT_DIR}/hdbpp-cm EXCLUDE_FROM_ALL)
add_subdirectory(${EXTERNAL_PROJECT_DIR}/libhdbpp EXCLUDE_FROM_ALL)
add_subdirectory(components/hdbpp-health-check EXCLUDE_FROM_ALL)
add_subdirectory(components/libhdbpp-timescale EXCLUDE_FROM_ALL)

# update the libhdbpp project
set_target_properties(libhdbpp_shared_library
    PROPERTIES
        ARCHIVE_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}"
        RUNTIME_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}"
        LIBRARY_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}")

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

# update the hdbpp-health-check project
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

# now create a phoney target that can build the entire project
add_custom_target(project)

add_dependencies(project 
    libhdbpp_shared_library 
    libhdbpp_timescale_shared_library 
    hdbpp_es 
    hdbpp_cm 
    hdbpp_health_check)

set_target_properties(project
    PROPERTIES
        RUNTIME_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}")