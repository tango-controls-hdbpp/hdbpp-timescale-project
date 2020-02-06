cmake_minimum_required(VERSION 3.2)

# source files
set(SRC_FILES ${SRC_FILES}
    ${CMAKE_CURRENT_SOURCE_DIR}/ClassFactory.cpp
    ${CMAKE_CURRENT_SOURCE_DIR}/HdbppHealthCheck.cpp
    ${CMAKE_CURRENT_SOURCE_DIR}/HdbppHealthCheckClass.cpp
    ${CMAKE_CURRENT_SOURCE_DIR}/HdbppHealthCheckStateMachine.cpp
    ${CMAKE_CURRENT_SOURCE_DIR}/HealthCheck.cpp
    ${CMAKE_CURRENT_SOURCE_DIR}/main.cpp
    PARENT_SCOPE)