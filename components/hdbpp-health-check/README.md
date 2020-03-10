# hdbpp-health-check

A simple Device Server to feedback errors and warnings into the Tango Control system from the hdbpp-cluster-reporting Rest API. Reports errors and warnings in its state:

- Errors reported as Fault state
- Warnings reported as Alarm state

## Building

Built as part of the parent projects consolidated build system. Can be built separately with the following advice.

### Toolchain Dependencies

If wishing to build the project, ensure the following dependencies are met:

* CMake 3.6 or higher
* C++14 compatible compiler (code base is using c++14)

### Build Dependencies

Ensure the development version of the dependencies are installed. These are as follows:

* Tango Controls 9 or higher development headers and libraries
* omniORB release 4 or higher development headers and libraries
* libzmq3-dev or libzmq5-dev

### Build

The build system uses pkg-config to find some dependencies, for example Tango. If Tango is not installed to a standard location, set PKG_CONFIG_PATH, i.e.

```bash
export PKG_CONFIG_PATH=/non/standard/tango/install/location
```

Then to build the entire project:

```
mkdir -p build
cd build
cmake ..
make
```

The pkg-config path can also be set with the cmake argument CMAKE_PREFIX_PATH. This can be set on the command line at configuration time, i.e.:

```
...
cmake -DCMAKE_PREFIX_PATH=/non/standard/tango/install/location ..
...
```

### Build Flags

The following build flags are available

#### Standard CMake Flags

The following is a list of common useful CMake flags and their use:

| Flag | Setting | Description |
|------|-----|-----|
| CMAKE_INSTALL_PREFIX | PATH | Standard CMake flag to modify the install prefix. |
| CMAKE_INCLUDE_PATH | PATH[S] | Standard CMake flag to add include paths to the search path. |
| CMAKE_LIBRARY_PATH | PATH[S] | Standard CMake flag to add paths to the library search path |
| CMAKE_BUILD_TYPE | Debug/Release | Build type to produce |

#### Project Flags

| Flag | Setting | Default | Description |
|------|-----|-----|-----|
| ENABLE_CLANG | ON/OFF | OFF | Clang code static analysis, readability, and cppcore guideline enforcement for any component that supports it|

Currently this flags lots of warnings from Pogo generated code.

## Configuration 

Once deployed, this Device Server requires several properties to be set correctly:

- RestAPIHost - The hostname of the server hosting the hdbpp-cluster-reporting Rest API.
- RestAPIPort - The port to access the hdbpp-cluster-reporting Rest API, default is 10666.
- RestAPIRootUrl - The root path of the endpoints. Default is /api/v1.

Without these, the hdbpp-health-check will not be able to connect and communicate with the Rest API.

Next enable the checks:

- EnableHostCheck - This will enable checking of the hosts and update the state of the hdbpp-health-check Device Server to Fault/Alarm + a message if it detects any errors.
