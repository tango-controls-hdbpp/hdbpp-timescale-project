# Cassandra to TimescaleDB import

[![TangoControls](https://img.shields.io/badge/-Tango--Controls-7ABB45.svg?style=flat&logo=%20data%3Aimage%2Fpng%3Bbase64%2CiVBORw0KGgoAAAANSUhEUgAAACAAAAAkCAYAAADo6zjiAAAABHNCSVQICAgIfAhkiAAAAAlwSFlzAAALEwAACxMBAJqcGAAAAsFJREFUWIXtl01IFVEYht9zU%2FvTqOxShLowlOgHykWUGEjUKqiocB1FQURB0KJaRdGiaFM7gzZRLWpTq2olhNQyCtpYCP1gNyIoUTFNnxZzRs8dzvw4Q6564XLnfOf73vedc2a%2BmZEKALgHrC3CUUR8CxZFeEoFalsdM4uLmMgFoIlZLJp3A9ZE4S2oKehhlaR1BTnyg2ocnW%2FxsxEDhbYij4EPVncaeASMAavnS%2FwA8NMaqACNQCew3f4as3KZOYh2SuqTVJeQNiFpn6QGSRVjTH9W%2FiThvcCn6H6n4BvQDvQWFT%2BSIDIFDAKfE3KOAQeBfB0XGPeQvgE67P8ZoB44DvTHmFgJdOQRv%2BUjc%2BavA9siNTWemgfA3TwGquCZ3w8szFIL1ALngIZorndvgJOR0GlP2gtJkzH%2Bd0fGFxW07NqY%2FCrx5QRXcYjbCbmxF1dkBSbi8kpACah3Yi2Sys74cVyxMWY6bk5BTwgRe%2BYlSzLmxNpU3aBeJogk4XWWpJKUeiap3RJYCpQj4QWZDQCuyIAk19Auj%2BAFYGZZjTGjksaBESB8P9iaxUBIaJzjZcCQcwHdj%2BS2Al0xPOeBYYKHk4vfmQ3Y8YkIwRUb7wQGU7j2ePrA1URx93ayd8UpD8klyPbSQfCOMIO05MbI%2BDvwBbjsMdGTwlX21AAMZzEerkaI9zFkP4AeYCPBg6gNuEb6I%2FthFgN1KSQupqzoRELOSed4DGiJala1UmOMr2U%2Bl%2FTWEy9Japa%2Fy41IWi%2FJ3d4%2FkkaAw0Bz3AocArqApwTvet3O3GbgV8qqjAM7bf4N4KMztwTodcYVyelywKSCD5V3xphNXoezuTskNSl4bgxJ6jPGVJJqbN0aSV%2Bd0M0aO7FCs19Jo2lExphXaTkxdRVgQFK7DZVDZ8%2BcpdmQh3wuILh7ut3AEyt%2B51%2BL%2F0cUfwFOX0t0StltmQAAAABJRU5ErkJggg%3D%3D)](http://www.tango-controls.org) [![License: GPL v3](https://img.shields.io/badge/License-GPL%20v3-blue.svg)](https://www.gnu.org/licenses/gpl-3.0)

- [Cassandra to TimescaleDB import](#Cassandra-to-TimescaleDB-import)
  - [Overview](#Overview)
  - [Dependencies](#Dependencies)
  - [Dump Cassandra data](#Dump-Cassandra-data)
    - [naming convention](#Naming-convention)
  - [Import script](#Import-script)
  - [Limitations and improvements](#Limitations-and-improvements)

This project describe a procedure to migrate HDB data from a cassandra cluster to a timescaleDB instance.

This guide do not describe how to install and set up the timescaleDB cluster.

## Overview

In order to import data from cassandra to timescaledb, we chose to first dump cassandra data to csv files, and then process them using a python script to import them into an existing TimescaleDB HDB cluster.
This guide Describes how to dump the cassandra cluster to csv files and then run the import script.

## Dependencies

To dump cassandra data, [Datastax dsbulk](https://docs.datastax.com/en/dsbulk/doc/dsbulk/reference/dsbulkCmd.html) might be needed.

On importing data, the schema [hdb_ext_import.sql](../schema/hdb_ext_import.sql) must be set on the target database. It breaks the FQDN into cs_name, family, domain, etc… This could be done in the python script, but it might as well be done in the database.

## Dump Cassandra data

Extracting data from casssandra can be a challenge, especially for large arrays. Before even starting, increasing the available memory as much as possible will increase the rate of success.

Cassandra comes with a command to dump entire tables to csv files: COPY.
To dump a table using it log to the Cassandra cluster and run:

```SQL
COPY att_conf TO att_conf.csv
COPY att_scalar_devdouble_ro TO att_scalar_devdouble_ro.csv
...
```

For more detailed options see the [official documentation](https://cassandra.apache.org/doc/latest/tools/cqlsh.html?highlight=copy#copy-to)

Nevertheless this command may fail on some tables (usually array table with big arrays). Upon failure, you can find the range that couldn't be extracted and try to do it again at a lower speed. This can be achieved with the PAGESIZE and MAXREQUESTS options. Increasing the timeout value might help. A low speed request might look like:

```SQL
COPY att_array_devdouble_ro TO att_array_devdouble_ro.csv WITH MAXREQUESTS=1 AND PAGESIZE=1 AND PAGETIMEOUT=60 AND MAXATTEMPTS=10 AND BEGINTOKEN=375742984298437549 AND ENDTOKEN=421553931176082414;
```

If one still has problem extracting data, one might use [Datastax dsbulk](https://docs.datastax.com/en/dsbulk/doc/dsbulk/reference/dsbulkCmd.html)
This tool provide finer control upon speed and timeouts so that you can extract all the data, even if it takes longer.

A common command line to extract the devdouble array table looks like (replace [hdbhost] with a proper value):

```bash
./dsbulk unload -url att_array_devdouble_ro.csv -cl QUORUM --driver.basic.request.timeout "60 minutes" --advanced.heartbeat.interval 600 --advanced.heartbeat.timeout 1200 --executor.maxPerSecond 800 -maxErrors -1 -h [hdbhost] -k hdb -t att_array_devdouble_ro
```

Note that usually reducing the speed reduces the number of errors.

### Naming convention

The import script will look for the csv data based on filename, so they must follow a certain convention.
Depending on the tool used to dump the data, the data is either in a single csv file, or a folder containing the csv files, both are supported.

The script expect the data to be in a file or folder named as the table name followed by the .csv extension.

Ex:

```bash
att_conf.csv
att_array_devfloat_ro.csv
att_scalar_devdouble_rw.csv
att_scalar_devdouble_ro.csv
```

Note that the att_conf.csv file is the dump of the att_conf table, and is the main input of the import script.

## Import script

Once all or part of the cassandra data has been dumped to csv files the script can be run to import data in the timescaledb cluster.

Be sure that all the csv files respect the [naming convention](#Naming-Convention) and are in the same folder.

Be sure that [hdb_ext_import.sql](../schema/hdb_ext_import.sql) has been set on the target database, otherwise the cs_name, family, etc… won't be set on the imported data.

The script comes with a [configuration file](conf/hdbpp_import.conf) in the yaml format that is commented. Some parameters are mandatory for the script to run properly:

 - hdb-cluster:connection: Contains the connection information to connect to the timescaledb instance. Adapt the parameters to your own setup.
 - csv_file: This is the path to the csv dump of the att_conf table. 

Then to execute the script use:

```bash
./hdbpp_import.py -c conf/hdbpp_import.conf
```

## Limitations and improvements

As it is, this guide was successfully used to migrate data, but suffers for some limitations.

  - Code quality: the script is not much more than a proof of concept, it should be refactored to improve readability and maintainability.
  - Logging: Some information should be logged in the separate processes, but it doesn't work.
  - Speed: The process is long. Data extraction from Cassandra can take some time, and for some type of data is not possible unless performed at low speed. This could be a problem the bigger the base is.
  The import script, then, can take a long time to run, but there are some ways to improve it:
    - Parallelize the code: The code is running in parallel, importing each file in a single process, but it could still be faster if we could load the files in small chunks. If the data was exported in multiple files we do not suffer from this issue.
    - Use a better query: There are different ways to insert data into postgresql using psycopg2 in python. An interesting comparative study can be found [here](https://hakibenita.com/fast-load-data-python-postgresql).

