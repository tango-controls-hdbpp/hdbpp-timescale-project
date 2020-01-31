#!/usr/bin/env python3

# -----------------------------------------------------------------------------
# This file is part of the hdbpp-timescale-project
#
# Copyright (C) : 2014-2019
#   European Synchrotron Radiation Facility
#   BP 220, Grenoble 38043, FRANCE
#
# hdbpp-timescale-project is free software: you can redistribute it and/or modify
# it under the terms of the Lesser GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# hdbpp-timescale-project is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the Lesser
# GNU General Public License for more details.
#
# You should have received a copy of the Lesser GNU General Public License
# along with hdbpp-timescale-project.  If not, see <http://www.gnu.org/licenses/>.
# -----------------------------------------------------------------------------

"""
Simple script to reorder the attribute data in the data tables. This must be done to archive
the query performance defined in the evaluation studies.

The script is built to be run once a day, and configured with a simple yaml style config
file. The config file may define multiple database clusters that a single instance of
this script will reorder.
"""

import os
import time
import sys
import argparse
import psycopg2
import yaml
import logging
import logging.handlers

from datetime import timedelta

logger = logging.getLogger('hdbpp-reorder-chunks')

version_major = 0
version_minor = 1
version_patch = 0
debug = False

# This is a fixed string in the schema, so rather than work it out with
# queries etc, we just use this as a postfix
idx_postfix = "_att_conf_id_data_time_idx"

# All available data tables in the hdb database, the script attempts to reorder
# chunks on all hyper tables in the hdb database
tables = [
    "att_array_devboolean",
    "att_array_devdouble",
    "att_array_devencoded",
    "att_array_devenum",
    "att_array_devfloat",
    "att_array_devlong",
    "att_array_devlong64",
    "att_array_devshort",
    "att_array_devstate",
    "att_array_devstring",
    "att_array_devuchar",
    "att_array_devulong",
    "att_array_devulong64",
    "att_array_devushort",
    "att_scalar_devboolean",
    "att_scalar_devdouble",
    "att_scalar_devencoded",
    "att_scalar_devenum",
    "att_scalar_devfloat",
    "att_scalar_devlong",
    "att_scalar_devlong64",
    "att_scalar_devshort",
    "att_scalar_devstate",
    "att_scalar_devstring",
    "att_scalar_devuchar",
    "att_scalar_devulong",
    "att_scalar_devulong64",
    "att_scalar_devushort"]


def valid_config(config):
    """Validate the yaml config. Certain values will be checked for, and if not present
    the config is considered not valid and false is returned

    Arguments:
        config : dict -- dictionary of values that represent the config. Loaded from yaml

    Returns:
        bool -- True on success, False otherwise
    """

    if len(config) == 0:
        logger.error("Invalid config file, no values loaded. Please check the config file is valid")
        return False

    for _, val in config.items():
        if "connection" not in val:
            logger.error("Missing section 'connection' in config file. Please check the config file is valid")
            return False

        else:
            if "user" not in val["connection"]:
                logger.error("No user defined in 'connection' section. Please check the config file is valid")
                return False

        if "schedule" not in val:
            logger.error("Missing section 'connection' in config file. Please check the config file is valid")
            return False

        else:
            if "window" not in val["schedule"]:
                logger.error("No window defined in 'connection' section. Please check the config file is valid")
                return False

            if len(val["schedule"]["window"].split()) == 2:
                schedule = val["schedule"]["window"].split()

                try:
                    i = int(schedule[0])
                except ValueError:
                    logger.error("The schedule must be of the format: NUMBER PERIOD example: 28 days")
                    return False

                if schedule[1] != "days" and schedule[1] != "hours" and schedule[1] != "week":
                    logger.error("The schedule period supports hours/days/weeks")
                    return False

    return True


def add_defaults_to_config(config):
    """
    Ensure the defaults for certain config params are part of the configuration

    Arguments:
        config : dict -- Configuration
    """

    for _, val in config.items():
        if "password" not in val["connection"]:
            val["connection"] = ""

        if "host" not in val["connection"]:
            val["host"] = "localhost"

        if "port" not in val["connection"]:
            val["port"] = "5432"

        if "database" not in val["connection"]:
            val["database"] = "hdb"


def load_config(path):
    """Load the config file from the given path

    Arguments:
        path : str -- Path and name of the config file to load

    Returns:
        dict -- dictionary of values from the yaml config file. 
    """

    with open(path, 'r') as fp:
        try:
            config = yaml.safe_load(fp)

        except yaml.YAMLError as error:
            logger.error("Unable to load the config file: {}. Error: {}".format(path, error))
            return None

    logger.info("Loaded config file: {}".format(path))

    # return the dictionary for the script to use
    return config

def write_config(path, config):
    """Write the config file from the given path

    Arguments:
        path : str -- Path and name of the config file to write

    """

    with open(path, 'w') as fp:
        try:
            yaml.safe_dump(config, fp)

        except yaml.YAMLError as error:
            logger.error("Unable to write the config file: {}. Error: {}".format(path, error))
            return None

    logger.info("Written config file: {}".format(path))


def reorder_table(table_name, server_config, schedule, ordered_chunks):
    """
    Perform a reorder chunks request on the given table name on the given
    server config. This function will open a connection, perform the action then
    close the connection.

    Arguments:
        table_name : str -- name of the table to reorder the chunks for
        server_config : dict -- dictionary of values from the config file that defines the server
        schedule : dict -- dictionary of keys from the config that defines the reorder schedule
        ordered_chunks : list -- list of chunks that have already been ordered

    Returns:
        bool -- True on success, False otherwise
    """

    # first attempt to open a connection to the database
    try:
        logger.debug("Attempting to connect to server: {}".format(server_config["host"]))

        # attempt to connect to the server
        connection = psycopg2.connect(
            user=server_config["user"],
            password=server_config["password"],
            host=server_config["host"],
            port=server_config["port"],
            database=server_config["database"])

        connection.autocommit = True

        logger.debug("Connected to database at server: {}".format(server_config["host"]))

    except (Exception, psycopg2.Error) as error:
        logger.error("Error: {}".format(error))
        return False

    # now we have a database connection, proceed to reorder the given table. The operation is
    # timed purely for information purposes
    try:
        start_time = time.monotonic()
        cursor = connection.cursor()
        logger.debug("Fetching the last '{}' of chunks....".format(schedule["window"]))

        # ensure we are clustering on the composite index
        cursor.execute("ALTER TABLE {} CLUSTER ON {}{};".format(table_name, table_name, idx_postfix))

        # get the config window of chunks to be reordered, we pass the window from the
        # configuration directly into the SQL, this is why its format is strictly enforced.
        cursor.execute("SELECT show_chunks('{}', newer_than => now() - interval '{}', older_than => now());".format(table_name, schedule["window"]))
        chunks = cursor.fetchall()
        logger.debug("Fetched {} chunk(s)".format(len(chunks)))

        for chunk in chunks:
            #Check if this chunk was already processed.
            if chunk[0] not in ordered_chunks:
                # do the actual reorder of the chunk
                logger.debug("Reordering chunk: {} in table: {}".format(chunk[0], table_name))
                cursor.execute("SELECT reorder_chunk('{}', index => '{}{}');".format(chunk[0], table_name, idx_postfix))
                logger.debug("Finished reordering chunk: {} in table: {}".format(chunk[0], table_name))
                ordered_chunks.append(chunk[0])
            else:
                logger.debug("Do not reorder previously ordered chunk: {} in table: {}".format(chunk[0], table_name))


        connection.commit()
        cursor.close()
        logger.debug("Reorder of table {} took: {}".format(table_name, timedelta(seconds=time.monotonic() - start_time)))
        connection.close()

    except (Exception, psycopg2.Error) as error:
        logger.error("Error reordering table: {}: {}".format(table_name, error))

        # closing database connection.
        if(connection):
            connection.close()
            logger.debug("Closed connection to server: {} due to error".format(server_config["host"]))

        return False

    connection.close()
    logger.debug("Closed connection to server: {}".format(server_config["host"]))

    return True


def run_command(args):
    """
    Command function hooked to argparse. 

    Arguments:
        args -- Arguments from the command line

    Returns:
        bool -- True for success, False otherwise.
    """

    if args.version is True:
        print("Version {}.{}.{}".format(str(version_major), str(version_minor), str(version_patch)))

    elif args.validate is True:
        config = load_config(args.config)

        if config is None:
            return False

        if not valid_config(config):
            return False

        logger.info("Config file appears to be valid")

    else:
        config = load_config(args.config)
        ordered_chunks = load_config(args.ordered_chunks)
        if config is None:
            return False

        # we have a config file, validate the config
        if valid_config(config):

            # config is valid, now check and add defaults where required
            add_defaults_to_config(config)

            # now reorder the tables with the given config for
            # each root entry in the config file
            for key, val in config.items():
                start_time = time.monotonic()
                logger.info("Processing reorder chunks configuration: {} with schedule: {}".format(key, val["schedule"]))

                for table in tables:
                    if ordered_chunks is not None:
                        if ordered_chunks[table] is None:
                            ordered_chunks[table] = []
                        if not reorder_table(table, val["connection"], val["schedule"], ordered_chunks[table]):
                            write_config(args.ordered_chunks, ordered_chunks)
                            logger.error("Breaking reorder tables attempt due to previous error")
                            return False

                logger.info("Processed reorder chunks configuration {} in: {}".format(key, timedelta(seconds=time.monotonic() - start_time)))
            write_config(args.ordered_chunks, ordered_chunks)

        else:
            return False

    return True


def main() -> bool:
    parser = argparse.ArgumentParser(description="HDB TimscaleDb reorder chunks service script")
    parser.add_argument("-v", "--version", action="store_true", help="version information")
    parser.add_argument("-d", "--debug", action="store_true", help="debug output for development")
    parser.add_argument("-c", "--config", default="/etc/hdb/reorder.conf", help="config file to use")
    parser.add_argument("-o", "--ordered_chunks", default="/var/lib/hdb/chunks.conf", help="File with the list of ordered chunks to use")
    parser.add_argument("--validate", action="store_true", help="validate the given config file")
    parser.add_argument("--syslog", action="store_true", help="send output to syslog")
    parser.set_defaults(func=run_command)

    if len(sys.argv) == 1:
        parser.print_help(sys.stderr)
        sys.exit(1)

    args = parser.parse_args()

    stdout_formatter = logging.Formatter("%(asctime)s hdbpp-reorder-chunks[%(process)d]: %(message)s", "%Y-%m-%d %H:%M:%S")
    stdout_handler = logging.StreamHandler()
    stdout_handler.setFormatter(stdout_formatter)
    logger.addHandler(stdout_handler)

    if args.syslog:
        syslog_formatter = logging.Formatter("hdbpp-reorder-chunks[%(process)d]: %(message)s")
        syslog_handler = logging.handlers.SysLogHandler(address='/dev/log')
        syslog_handler.setFormatter(syslog_formatter)
        logger.addHandler(syslog_handler)

    if args.debug:
        logger.setLevel(logging.DEBUG)
    else:
        logger.setLevel(logging.INFO)

    return args.func(args)


if __name__ == "__main__":
    result = main()

    if result is not True:
        logger.error("Command failed\n")
