ARG PG_VERSION
ARG TDB_VERSION
FROM timescale/timescaledb:${TDB_VERSION}-${PG_VERSION}

COPY build-files/schema/hdb_schema.sql  /docker-entrypoint-initdb.d/901_hdb_schema.sql
COPY build-files/schema/hdb_roles.sql  /docker-entrypoint-initdb.d/902_hdb_roles.sql

USER root
RUN chown postgres:postgres /docker-entrypoint-initdb.d/901_hdb_schema.sql
RUN chown postgres:postgres /docker-entrypoint-initdb.d/902_hdb_roles.sql