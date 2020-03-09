# hdbpp-timescale-docker

Test Docker image for quickly setting up a test database to develop against. This has not been tested as a production database, but since its derived from the original TimescaleDb Docker image there is no reason it should not be suitable for simple deployments

The container includes the following schema:

- hdb_schema.sql - The base tables etc.
- hdb_roles.sql - The read and read/write roles.

Any schema extensions currently have to added by hand.

## Building

Build the docker image using the Makefile:

```bash
make
```

If using a Docker registry then the Makefile can push the image to your registry (remember to update docker commands to include your registry address):

```bash
export DOCKER_REGISTRY=<your registry here>
make push
```

To clean an existing build:

```bash
make clean
```

## Running

The container can be run with persistent storage:

```bash
docker run --rm -d -p 5432:5432 -v /your/data/dir:/var/lib/postgresql/data -e POSTGRES_PASSWORD=password --name hdbpp-test-db hdbpp-timescale:latest
```

Or without persistent storage:

```bash
docker run --rm -d -p 5432:5432 -e POSTGRES_PASSWORD=password --name hdbpp-test-db hdbpp-timescale:latest
```

## License

The source code is released under the LGPL3 license and a copy of this license is provided with the code.
