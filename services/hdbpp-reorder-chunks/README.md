# hdbpp-reorder-chunks

- [hdbpp-reorder-chunks](#hdbpp-reorder-chunks)
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

This project provides a means to ensure the timescale database data is kept in the optimal query order. To ensure the data can be queried quickly on an attribute basis, it is ordered by att_conf_id and data_time, this is not the same as the insert order, which is data_time (since its received in real time). Without reordering the data, the query performance is seriously degraded.

To achieve this reordering, we run a simple script that reorders the last X days of chunks (default is 28). It is recommended this script is run every day at midnight to ensure any data inserted over the last day is optimised. It should not be necessary to run the script more often, but it is possible if the scenario requires it.

It is recommended (and pre-configured) to run in the evening, when the system is not being heavily used.

A single deployment of the script can manage multiple databases or database clusters if it is configured correctly. See the configuration file.

## Dependencies

Following Python dependencies are required for direct deployment:

* pyyaml
* psycopg2-binary

## Usage

The script has a simple command line help menu with some helpful utilities. To view:

```bash
./hdbpp_reorder_chunks.py --help
```

## Deployment

The script can be deployed directly or as a docker image.

### Docker (Recommended)

The Docker image is designed to allow the user to mount the configuration file to /etc/hdb/hdbpp_reorder_chunks.conf. This can be skipped and the configuration file under setup edited directly before building the Docker image, but the docker image will have to be rebuilt for each config change.

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
cp setup/hdbpp_reorder_chunks.conf /etc/hdb/hdbpp_reorder_chunks.conf
```

You should keep a list of the chunk that are ordered in a yaml file. If this is the first deployment you can copy an empty one into place ont the system that will run the Docker container:

```bash
mkdir -p /var/lib/hdb
cp setup/chunks.conf /var/lib/hdb/chunks.conf
```

Then run the container with the config file mounted to /etc/hdb/hdbpp_reorder_chunks.conf and the reordered chunk list file mounted to /var/lib/hdb/chunks.conf (add the registry name if required):

```
docker run -d -v /etc/hdb/hdbpp_reorder_chunks.conf:/etc/hdb/hdbpp_reorder_chunks.conf:ro /var/lib/hdb/chunks.conf:/var/lib/hdb/chunks.conf:rw --rm --name hdbpp_reorder_chunks hdbpp-reorder-chunks
```

#### Validation

To check if the job is scheduled:

```
docker exec -ti hdbpp_reorder_chunks bash -c "crontab -l"
```

To check if the cron service is running:

```
docker exec -ti hdbpp_reorder_chunks bash -c "grep cron"
```

#### Logs

Check log output from the cron job and ensure you see data being reordered on a daily basis:

```
docker logs hdbpp_reorder_chunks
```

### Direct

If deploying directly, the Python requirements must be met:

```
pip install -r requirements.txt
```

Once setup, the script and its setup files must be installed. Copy the main script into a system path:

```bash
cp hdbpp_reorder_chunks.py /usr/local/bin
```

Copy the cron file into place (take the one without docker in the name). The trigger is every 24 hours at 00:00, this can be changed to any schedule by editing the file:

```bash
cp setup/hdbpp_reorder_chunks /etc/cron.d
```

Finally copy the example config into place and customize it:

```bash
mkdir -p /etc/hdb
cp setup/hdbpp_reorder_chunks.conf /etc/hdb/hdbpp_reorder_chunks.conf
```

#### Logs

The direct deploy cron file redirects logging to syslog. Therefore a simple grep for 'hdbpp-reorder-chunks' in the syslog will show when and what the result was of the last run.

## Configuration

The example config file setup/hdbpp_reorder_chunks is commented for easy customisation.

## License

The source code is released under the LGPL3 license and a copy of this license is provided with the code.
