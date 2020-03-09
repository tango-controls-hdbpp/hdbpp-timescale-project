# Deployment

- [Deployment](#Deployment)
  - [Component Deployment](#Component-Deployment)
    - [Component Dependencies](#Component-Dependencies)
    - [Configuration](#Configuration)
      - [libhdbpp-timescale](#libhdbpp-timescale)
  - [Service Deployment](#Service-Deployment)
    - [hdbpp-reorder-chunks (Required)](#hdbpp-reorder-chunks-Required)
    - [hdbpp-ttl (Optional)](#hdbpp-ttl-Optional)
    - [hdbpp-cluster-reporting (Optional)](#hdbpp-cluster-reporting-Optional)

Deployment is composed of two phases, the binary components from the consolidated build (hdbpp-es etc) and the services.

## Component Deployment

Once built, all the component binaries are available directly in the build directory. These must be installed as per the policy you have on site. 

### Component Dependencies

The various components have the following system package dependencies:

- Tango Controls 9 or higher
- omniORB release 4 or higher
- libzmq3 or libzmq5
- libpq5

### Configuration

General hdb++ setup and configuration is outside the scope of this project. Please see the tango [readthedocs](https://tango-controls.readthedocs.io/en/latest/) project for general information. 

#### libhdbpp-timescale

The GitHub [repository](https://github.com/tango-controls-hdbpp/libhdbpp-timescale) for this project details the configuration parameters that must be passed to the library from the hdbpp-es/hdbpp-cm.

## Service Deployment

At the minimum a production cluster needs to run the [hdbpp-reorder-chunks](../service/hdbpp-reorder-chunks/README.md) service to put the data tables in to the optimal order for querying.

Other services are optional.

### hdbpp-reorder-chunks (Required)

Follow the hdbpp-reorder-chunks [README](../service/hdbpp-reorder-chunks/README.md) for deployment. The recommended method is Docker deployment.

### hdbpp-ttl (Optional)

This is an optional service. Deploy this if you intend to use the Time To Live flag on attributes. This service will delete expired data when it is run.

Follow the hdbpp-ttl [README](../service/hdbpp-ttl/README.md) for deployment. The recommended method is Docker deployment.

### hdbpp-cluster-reporting (Optional)

This is an optional service. 