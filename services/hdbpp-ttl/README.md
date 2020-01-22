# hdbpp-ttl

In the hdbpp database schema each attribute defines a field to implement a time to live for each attributes data. Since TimescaleDb does not offer this type of feature, it has been implemented separately as this small python script. Deleting data from the database takes advantage of TimescaleDb's ability to efficiently delete data across its chunked hyper-tables, and only lock the chunks and not the entire table while the operation is carried out.

The script will remove data older than the time to live value, and this is calculated from midnight yesterday. For example, a time to live of 1 day would preserve all of yesterdays data, what ever time it is run today. A time to live of 2 days would preserve yesterday and the day before yesterday, what ever time it is run.

It is recommended (and pre-configured) to run in the evening, when the system is not being heavily used.

## Dependencies

Following Python dependencies must be installed: 

* pyyaml
* psycopg2-binary

## Deployment

The script can be deployed directly or as a docker image.

### Direct

If deploying directly, the Python requirements must be met:

```
pip install -r requirements.txt
```

Once setup, the script and its setup files must be installed. Copy the main script into a system path:

```bash
cp hdbpp_ttl.py /usr/local/bin
```

Copy the cron file into place (take the one without docker in the name). The trigger is every 24 hours at 22:00, this can be changed to any schedule by editing the file:

```bash
cp setup/hdbpp_ttl /etc/cron.d
```

Finally copy the example config into place and customize it:

```bash
mkdir -p /etc/hdb
cp setup/example_hdbpp_ttl.conf /etc/hdb/hdbpp_ttl.conf
```

### Docker (recommended)

The Docker image is designed to allow the user to mount the configuration file to /etc/hdb/hdbpp_ttl.conf. This can be skipped and the configuration file under setup edited directly before building the Docker image.

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
cp setup/example_hdbpp_ttl.conf /etc/hdb/hdbpp_ttl.conf
```

Then run the container with the config file mounted to /etc/hdb/hdbpp_ttl.conf:

```
docker run -d -v /etc/hdb/hdbpp_ttl.conf:/etc/hdb/hdbpp_ttl.conf:ro --rm --name hdbpp_ttl hdbpp-ttl
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

Check log output from the cron job and ensure you see data being removed:

```
docker logs hdbpp_tll
```

## Configuration

The example config file setup/hdbpp_ttl is commented for easy customisation.

## License

The source code is released under the LGPL3 license and a copy of this license is provided with the code.