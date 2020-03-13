# Database Schema Configuration

Schema setup and management is a very important aspect to running the HDB++ system with TimescaleDb. The following presents guidelines and a setup plan, but it is not exhaustive and additional information is welcome.

Some of the information assumes familiarity with TimescaleDb terms and technologies. Please to TimescaleDb [documentation](www.timescaledb.com) for more information.

- [Database Schema Configuration](#Database-Schema-Configuration)
  - [Hypperchunk Sizes](#Hypperchunk-Sizes)
  - [Schema Description](#Schema-Description)
  - [Schema Setup](#Schema-Setup)
    - [Admin User](#Admin-User)
    - [Table Creation - Mandatory (Using hdb_schema.sql)](#Table-Creation---Mandatory-Using-hdbschemasql)
    - [Roles - Recommended (Using hdb_users.sql)](#Roles---Recommended-Using-hdbuserssql)
    - [Users - Optional (Using hdb_ext_users.sql)](#Users---Optional-Using-hdbextuserssql)
    - [Aggregates - Optional (Using hdb_ext_aggregates.sql)](#Aggregates---Optional-Using-hdbextaggregatessql)
    - [Clean-up](#Clean-up)

## Hypperchunk Sizes

The [schema](../resources/db-schema/hdb_schema.sql) file has default values set for all hyper table chunk sizes. It is assumed initial deployment data load will be smaller than the final fully operational system, so chunk sizes are as follows:

- 28 days for all data tables, except:
- 14 days for att_scalar_devdouble, since this appears to be used more often than other tables.

These values can, and should be, adjusted to the deployment situation. Please see the TimescaleDb [documentation](www.timescaledb.com) for information on choosing chunk sizes.

Important: These are initial values, the expectation is the database will be monitored and values adjusted as it takes on its full load.

## Schema Description

The schemea is stored under resources/schema in a series of sql files. This allows a deploying user to select just the base system, or extend the functionality with additional features.

The base schema files are as follows:

- hdb_schema.sql - This is the hdb table schema and required for all systems.
- hdb_roles.sql - This schema sets up read and read/write roles for the database. This provides the basis for defining database users.

Extended/optional schema files:

- hdb_ext_aggregates.sql - Provides TimescaleDb continuously updated aggregate views for multiple time periods. Periods are 1 min, 10 min, 1 hour, 8 hours and 1 day. Also includes the commands (in commented out state) to remove the views.
- hdb_ext_users.sql - Provides some basic user roles based on the hdb_roles.sql sql.

## Schema Setup

General setup steps.

### Admin User

Rather than create and manage the tables via a superuser, we create and admin user and have them create the tables:

```sql
CREATE ROLE hdb_admin WITH LOGIN PASSWORD 'hdbpp';
ALTER USER hdb_admin CREATEDB;
ALTER USER hdb_admin CREATEROLE;
ALTER USER hdb_admin SUPERUSER;
```

Note the SUPERUSER role will be stripped after the tables are set up.

### Table Creation - Mandatory (Using hdb_schema.sql)

Now import the hdb_schema.sql as the hdb_admin user. From pqsl:

```bash
psql -U hdb_admin -h HOST -p PORT-f hdb_schema.sql  -d template1
```

Note: we use database template1 since hdb_admin currently has no database to connect to.

We should now have a hdb database owned by hdb_admin.

### Roles - Recommended (Using hdb_roles.sql)

Next we need to set up the users (this may require some improvements, pull requests welcome). Connect as a superuser and create two roles using hdb_roles.sql

```
\i hdb_roles.sql
```

### Users - Optional (Using hdb_ext_users.sql)

Connect as a superuser and create users based on the roles by importing the sql file.

```
\i hdb_ext_users.sql
```

Some are suggested in hdb_ext_users.sql. Here we create three users that external applications will use to connect to the database. You may create as many and in what ever role you want.

### Aggregates - Optional (Using hdb_ext_aggregates.sql)

If you wish to use the continuous aggregate views, then run the sql file hdb_ext_aggregates.sql as super user. This will create all the aggregate views. If you want a subset of views, or to load them in layers to ensure the database hardware can handle the load, then edit the file and remove views you do not need, or want to add later.

```
\i hdb_ext_aggregates.sql
```

### Clean-up

Finally, strip the SUPERUSER trait from hdb_admin:

```sql
ALTER USER hdb_admin NOSUPERUSER;
```
