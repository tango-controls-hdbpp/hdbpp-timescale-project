# hdbpp-timescale-project

This repository is a work in progress, call back soon....

## Cloning 

This project contains several other projects as dependencies. Currently the project is configured to express its dependencies as sub-modules. To successfully clone the project and all its dependencies use the following git command:

```bash
git clone --recurse-submodules https://github.com/tango-controls-hdbpp/hdbpp-timescale-project.git
```

## Overview

This project consolidates several other hdbpp projects into a single repository, and acts as a location to store all support tools and services for the hdbpp deployment based on TimescaleDb. The project contents is contained in the following sections/folders:

* Services. Mainly python scripts run in Docker images to perform various functions on the database. 
* Device Servers. Including any device servers built for this project. This section also includes via sub modules device servers required for the deployment of the hdbpp project. Including these here allows the entire project to be built with a single command.
* Resources. A collection of helpful resources, such as Docker images, test scripts etc, that can allow a user to test the project quickly.
* Experimental: Any currently experimental work that is not ready for production use.

## Version Table

Since this project contains multiple elements, this table keeps an overview of the various versions.

Coming soon

## License

The code is released under the LGPL3 license and a copy of this license is provided with the code. Full license [here](LICENSE.md)
