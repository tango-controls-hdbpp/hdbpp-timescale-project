# hdbpp-cluster-reporting

- [hdbpp-cluster-reporting](#hdbpp-cluster-reporting)
  - [Dependencies](#Dependencies)
  - [Usage](#Usage)
  - [Rest API](#Rest-API)
  - [Deployment](#Deployment)
    - [Docker (Recommended)](#Docker-Recommended)
      - [Logs](#Logs)
    - [Direct (Untested)](#Direct-Untested)
      - [Logs](#Logs-1)
      - [Validation](#Validation)
      - [Logs](#Logs-2)
  - [Configuration](#Configuration)
  - [License](#License)

WORK IN PROGRESS - Current release is still a development release.

This is a Python/Flash based server to summarise various data points about a hdbpp database cluster installation. The aim is to aggregate common health points and status into a simple Rest Api that can be read from a viewer application. 

## Dependencies

Following Python dependencies are required for direct deployment:

* pyyaml
* apscheduler
* flask
* flask-restful
* requests
* Flask-RestPlus
* Flask-SQLAlchemy

## Usage

The script has a simple command line help menu with some helpful utilities. To view:

```bash
./run_server.py --help
```

## Rest API

If the server is deployed as configured (port 10666), then the Rest API can be found at

```
http://localhost:10666/api/v1/
```

Since this is still run as a development version, then a Swagger web page will be presented and it will be possible to query the various endpoints. When the prodcution release is finalised and deployed, this feature will only be available in development builds.

## Deployment

The script can be deployed directly or as a docker image.

### Docker (Recommended)

The Docker image is designed to allow the user to mount the configuration file to /etc/hdb/hdbpp_cluster_reporting.conf. This can be skipped and the configuration file under setup edited directly before building the Docker image, but the docker image will have to be rebuilt for each config change.

Build and deploy the Docker image:

```
cd docker
make
```

If using a Docker registry then the Makefile can push the image to your registry (remember to update docker commands to include your registry address):

```
export DOCKER_REGISTRY=<your registry here>
make push
```

Copy the example config into place on the system that will run the Docker container:

```bash
mkdir -p /etc/hdb
cp setup/hdbpp_cluster_reporting.conf /etc/hdb/hdbpp_cluster_reporting.conf
```

Then run the container with the config file mounted to /etc/hdb/hdbpp_cluster_reporting.conf (add the registry name if required):

```
docker run -d \
    -v /etc/hdb/hdbpp_cluster_reporting.conf:/etc/hdb/hdbpp_cluster_reporting.conf:ro \
    -v /var/lib/hdbpp-cluster-reporting:/var/lib/hdbpp-cluster-reporting \
    -p 10666:10666 -p 8008:8008 \
    --rm \
    --name hdbpp_cluster_reporting \
    hdbpp-cluster-reporting
```

#### Logs

Check log output from the cron job and ensure you see data being removed:

```
docker logs hdbpp_cluster_reporting
```

### Direct (Untested)

Its possible to run this way, but you will need to setup and user some kind of process manager, i.e. supervisord. This is out of the scope of this README.

If deploying directly, the Python requirements must be met:

```
pip install -r requirements.txt
```

Copy the python files to an install location, i.e:

```bash
cp -rf server /your/install/dir/app
cp run_server.py /your/install/dir/app
```

Copy the example config into place and customize it:

```bash
mkdir -p /etc/hdb
cp setup/hdbpp_cluster_reporting.conf /etc/hdb/hdbpp_cluster_reporting.conf
```

Now setup a process manager, i.e. supervisord to run the server. The run command should look something like this:

```bash
/usr/src/app/run_server.py -c /etc/hdb/hdbpp_cluster_reporting.conf
```

#### Logs

The direct deploy cron file redirects logging to syslog. Therefore a simple grep for 'hdbpp-cluster-reporting' in the syslog will show when and what the result was of the last run.

## Configuration

The example config file setup/hdbpp_cluster_reporting.conf is commented for easy customisation.

## License

The source code is released under the LGPL3 license and a copy of this license is provided with the code.
