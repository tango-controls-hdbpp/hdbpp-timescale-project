ARG PG_VERSION
FROM timescale/timescaledb:latest-${PG_VERSION}

COPY build-files/schema/hdb_schema.sql  /docker-entrypoint-initdb.d/901_hdb_schema.sql
COPY build-files/schema/hdb_roles.sql  /docker-entrypoint-initdb.d/902_hdb_roles.sql
COPY resources/init-hdbpp-db.sh  /docker-entrypoint-initdb.d/901_init-hdbpp-db.sh

USER root
RUN chown postgres:postgres /docker-entrypoint-initdb.d/901_init-hdbpp-db.sh
RUN chown postgres:postgres /docker-entrypoint-initdb.d/901_hdb_schema.sql
RUN chown postgres:postgres /docker-entrypoint-initdb.d/902_hdb_roles.sql