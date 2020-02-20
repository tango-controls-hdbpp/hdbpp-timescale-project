# hdbpp-timescale-project

[![TangoControls](https://img.shields.io/badge/-Tango--Controls-7ABB45.svg?style=flat&logo=%20data%3Aimage%2Fpng%3Bbase64%2CiVBORw0KGgoAAAANSUhEUgAAACAAAAAkCAYAAADo6zjiAAAABHNCSVQICAgIfAhkiAAAAAlwSFlzAAALEwAACxMBAJqcGAAAAsFJREFUWIXtl01IFVEYht9zU%2FvTqOxShLowlOgHykWUGEjUKqiocB1FQURB0KJaRdGiaFM7gzZRLWpTq2olhNQyCtpYCP1gNyIoUTFNnxZzRs8dzvw4Q6564XLnfOf73vedc2a%2BmZEKALgHrC3CUUR8CxZFeEoFalsdM4uLmMgFoIlZLJp3A9ZE4S2oKehhlaR1BTnyg2ocnW%2FxsxEDhbYij4EPVncaeASMAavnS%2FwA8NMaqACNQCew3f4as3KZOYh2SuqTVJeQNiFpn6QGSRVjTH9W%2FiThvcCn6H6n4BvQDvQWFT%2BSIDIFDAKfE3KOAQeBfB0XGPeQvgE67P8ZoB44DvTHmFgJdOQRv%2BUjc%2BavA9siNTWemgfA3TwGquCZ3w8szFIL1ALngIZorndvgJOR0GlP2gtJkzH%2Bd0fGFxW07NqY%2FCrx5QRXcYjbCbmxF1dkBSbi8kpACah3Yi2Sys74cVyxMWY6bk5BTwgRe%2BYlSzLmxNpU3aBeJogk4XWWpJKUeiap3RJYCpQj4QWZDQCuyIAk19Auj%2BAFYGZZjTGjksaBESB8P9iaxUBIaJzjZcCQcwHdj%2BS2Al0xPOeBYYKHk4vfmQ3Y8YkIwRUb7wQGU7j2ePrA1URx93ayd8UpD8klyPbSQfCOMIO05MbI%2BDvwBbjsMdGTwlX21AAMZzEerkaI9zFkP4AeYCPBg6gNuEb6I%2FthFgN1KSQupqzoRELOSed4DGiJala1UmOMr2U%2Bl%2FTWEy9Japa%2Fy41IWi%2FJ3d4%2FkkaAw0Bz3AocArqApwTvet3O3GbgV8qqjAM7bf4N4KMztwTodcYVyelywKSCD5V3xphNXoezuTskNSl4bgxJ6jPGVJJqbN0aSV%2Bd0M0aO7FCs19Jo2lExphXaTkxdRVgQFK7DZVDZ8%2BcpdmQh3wuILh7ut3AEyt%2B51%2BL%2F0cUfwFOX0t0StltmQAAAABJRU5ErkJggg%3D%3D)](http://www.tango-controls.org) [![License: GPL v3](https://img.shields.io/badge/License-GPL%20v3-blue.svg)](https://www.gnu.org/licenses/gpl-3.0) [![](https://img.shields.io/github/release/tango-controls-hdbpp/hdbpp-timescale-project.svg)](https://github.com/tango-controls-hdbpp/hdbpp-timescale-project/releases)

- [hdbpp-timescale-project](#hdbpp-timescale-project)
  - [Cloning](#Cloning)
  - [Overview](#Overview)
    - [services/*](#services)
    - [device-servers/*](#device-servers)
    - [resources/*](#resources)
    - [external/*](#external)
  - [Version Table](#Version-Table)
  - [License](#License)

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
