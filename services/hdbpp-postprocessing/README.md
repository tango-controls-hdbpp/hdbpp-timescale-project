# hdbpp-postprocessing

- [hdbpp-postprocessing](#hdbpp-postprocessing)
  - [Dependencies](#Dependencies)
  - [Usage](#Usage)
  - [Deployment](#Deployment)
    - [Docker (Recommended)](#Docker-Recommended)
      - [Validation](#Validation)
      - [Logs](#Logs)
    - [Direct](#Direct)
      - [Logs](#Logs-1)
  - [Configuration](#Configuration)
  - [License](#License)

In the hdbpp database extension schema hdbpp_ext_postprocessing.sql, we define tables to define and monitor the execution of jobs. In the latest versions of TimescaleDB (see [https://docs.timescale.com/timescaledb/latest/overview/release-notes/changes-in-timescaledb-2/#jobs]), a similar feature is implemented as well, rendering these schemas and scripts useless.
In order to help transition, the data model used is trying to mimick the one defined it TimescaleDB version 2.

The script will get information on which procedure to call from the table postprocessing_jobs, call them and then update the postprocessing_jobs_stats table with the relevant information.

No postprocessing procedure is implemented by default, so the script shouldn't do anything at first, this part is left to the user.

A single deployment of the script can manage multiple databases or database clusters if it is configured correctly. See the configuration file.

## Dependencies

Following Python dependencies are required for direct deployment:

* pyyaml
* psycopg2-binary

## Usage

The script has a simple command line help menu with some helpful utilities. To view:

```bash
./hdbpp_postprocessing.py --help
```

## Deployment

The script can be deployed directly or as a docker image.

### Docker (Recommended)

The Docker image is designed to allow the user to mount the configuration file to /etc/hdb/hdbpp_postprocessing.conf. This can be skipped and the configuration file under setup edited directly before building the Docker image, but the docker image will have to be rebuilt for each config change.

Build and deploy the Docker image:

```bash
cd docker
make
```

If using a Docker registry then the Makefile can push the image to your registry (remember to update docker commands to include your registry address):

```bash
export DOCKER_REGISTRY=<your registry here>
make push
```

Copy the example config into place on the system that will run the Docker container:

```bash
mkdir -p /etc/hdb
cp setup/hdbpp_postprocessing.conf /etc/hdb/hdbpp_postprocessing.conf
```

Then run the container with the config file mounted to /etc/hdb/hdbpp_postprocessing.conf (add the registry name if required):

```bash
docker run -d \
  -v /etc/hdb/hdbpp_postprocessing.conf:/etc/hdb/hdbpp_postprocessing.conf:ro \
  --rm \
  --name hdbpp_postprocessing \
  hdbpp-postprocessing
```

To clean an existing build:

```bash
make clean
```

#### Validation

To check if the job is scheduled:

```bash
docker exec -ti hdbpp_postprocessing bash -c "crontab -l"
```

To check if the cron service is running:

```bash
docker exec -ti hdbpp_postprocessing bash -c "grep cron"
```

#### Logs

Check log output from the cron job and ensure you see data being removed:

```
docker logs hdbpp_postprocessing
```

### Direct

If deploying directly, the Python requirements must be met:

```bash
pip install -r requirements.txt
```

Once setup, the script and its setup files must be installed. Copy the main script into a system path:

```bash
cp hdbpp_postprocessing.py /usr/local/bin
```

Copy the cron file into place (take the one without docker in the name). The trigger is every 24 hours at 22:00, this can be changed to any schedule by editing the file:

```bash
cp setup/hdbpp_postprocessing /etc/cron.d
```

Finally copy the example config into place and customize it:

```bash
mkdir -p /etc/hdb
cp setup/hdbpp_postprocessing.conf /etc/hdb/hdbpp_postprocessing.conf
```

#### Logs

The direct deploy cron file redirects logging to syslog. Therefore a simple grep for 'hdbpp_postprocessing' in the syslog will show when and what the result was of the last run.

## Configuration

The example config file setup/hdbpp_processing is commented for easy customisation.

## License

The source code is released under the LGPL3 license and a copy of this license is provided with the code.
