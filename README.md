# hdbpp-timescale-project

This repository is a work in progress, call back soon....

## Cloning 

This project contains several other projects as dependencies. Currently the project is configured to express its dependencies as sub-modules. To successfully clone the project and all its dependencies use the following git command:

```bash
git clone --recurse-submodules https://github.com/tango-controls-hdbpp/hdbpp-timescale-project.git
```

## Overview

This project consolidates several other hdbpp projects into a single repository, and acts as a location to store all support tools and services for the hdbpp project based on TimescaleDb. Brief overview of the modules:

### services/*

Contains various services deployed to assist in running the hdbpp database cluster operation. Its recommended to use the Docker images to ease deployment.

### device-servers/*

This is also the location for any TimescaleDb centric device servers.

### resources/*

Project resources. Including the HDB++ schema, TimescaleDB HDB++ Docker images, test scripts that can allow a user to test the project quickly.

### external/* 

This directory will be created at CMake configuration time and will contain the external dependencies for the complete build. These are hdbpp-es, hdbpp-cm, and libhdbpp.

## Version Table

Since this project contains multiple elements, this table keeps an overview of the various versions.

Coming soon

## License

The code is released under the LGPL3 license and a copy of this license is provided with the code. Full license [here](LICENSE.md)
