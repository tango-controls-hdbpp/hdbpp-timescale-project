# Building Guide

- [Building Guide](#Building-Guide)
  - [Dependencies](#Dependencies)
    - [Toolchain Dependencies](#Toolchain-Dependencies)
    - [Build Dependencies](#Build-Dependencies)
  - [Building](#Building)
  - [Build Flags](#Build-Flags)
    - [Standard CMake Flags](#Standard-CMake-Flags)
    - [Project Flags](#Project-Flags)

## Dependencies

The project has two types of dependencies, those required by the toolchain, and those to do the actual build. Build dependencies are a result of the external project requirements.

### Toolchain Dependencies

If wishing to build the project, ensure the following dependencies are met:

- CMake 3.11 or higher (The consolidated build uses the latest project fetch features from CMake)
- C++14 compatible compiler (code base in external projects is using c++14)

### Build Dependencies

Ensure the development version of the dependencies are installed. These are as follows:

- Tango Controls 9 or higher development headers and libraries
- omniORB release 4 or higher development headers and libraries
- libzmq3-dev or libzmq5-dev
- libpq-dev - Postgres C development library

## Building

The build system of the various components uses pkg-config to find some dependencies, for example Tango. If Tango is not installed to a standard location, set PKG_CONFIG_PATH, i.e.

```bash
export PKG_CONFIG_PATH=/non/standard/tango/install/location
```bash

Then to build just the library:

mkdir -p build
cd build
cmake ..
make project
```

The pkg-config path can also be set with the cmake argument CMAKE_PREFIX_PATH. This can be set on the command line at configuration time, i.e.:

```
...
cmake -DCMAKE_PREFIX_PATH=/non/standard/tango/install/location ..
...
```

The consoldiated build system updates the binary output for each compoent to be the build directly. When builing the entire project, all binaries will be under 'build'.

### Building Components Individually

It is possible to build the various components individually (incluing externally fetched ones). To see the available targets, use make as follows:

```bash
make help
```

Select a target, example hdbpp_cm, then:

```bash
make hdbpp_cm
```

## Build Flags

The following build flags are available

### Standard CMake Flags

The following is a list of common useful CMake flags and their use:

| Flag | Setting | Description |
|------|-----|-----|
| CMAKE_INSTALL_PREFIX | PATH | Standard CMake flag to modify the install prefix. |
| CMAKE_INCLUDE_PATH | PATH[S] | Standard CMake flag to add include paths to the search path. |
| CMAKE_LIBRARY_PATH | PATH[S] | Standard CMake flag to add paths to the library search path |
| CMAKE_BUILD_TYPE | Debug/Release | Build type to produce |

### Project Flags

| Flag | Setting | Default | Description |
|------|-----|-----|-----|
| ENABLE_CLANG | ON/OFF | OFF | Clang code static analysis, readability, and cppcore guideline enforcement for any component that supports it|
