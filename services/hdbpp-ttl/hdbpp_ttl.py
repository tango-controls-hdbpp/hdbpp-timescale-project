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
This simple script implements a time to live feature for the hdbpp database project.
The script reads the attributes ttl field, and if set, removes all data over the time
to live age for that attribute

It is important to note how the script calculates the data to remove. It works on the 
basis that yesterday is the first day of a time to live value, i.e. todays data is
always kept. A time to live value of 1 day would remove all data older than yesterday.
Time calculations are made from midnight.

The script is built to be run once a day, and configured with a simple yaml style config
file. The config file may define multiple database clusters that a single instance of
this script will delete dta from.
"""

import os
import time
import datetime
import sys
import argparse
import math
import psycopg2
import yaml
import logging
import logging.handlers
import hdbpp_rest_report as reporting

from datetime import timedelta

logger = logging.getLogger('hdbpp-ttl')

version_major = 0
version_minor = 2
version_patch = 0
debug = False


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

        if "rest_endpoint" in val:
            if not reporting.valid_config(val["rest_endpoint"]):
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
        
        if "compress_threshold_days" not in val:
            val["compress_threshold_days"] = 0

        if "rest_endpoint" not in val:
            val["rest_endpoint"] = {}
       
        reporting.add_defaults_to_config(val["rest_endpoint"])

        if "db_report" not in val:
            val["db_report"] = {"enabled": False}
        else:
            if "enabled" not in val["db_report"]:
                val["db_report"]["enabled"] = False


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

    # return the dictionary with the configuration in for the script to use
    return config

def connect(server_config):
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

    return connection

def push_report_to_db(server_config, ttl_report):
    """
    This function opens a connection to the server and writes the result
    of the script into a table used for monitoring purposes.
    """
    # first attempt to open a connection to the database
    try:

        connection = connect(server_config)

    except (Exception, psycopg2.Error) as error:
        logger.error("Error: {}".format(error))
        return False

    # now we have a database connection, proceed and writes the report
    try:
        cursor = connection.cursor()

        # Add the job information and retrieve the job id to insert the statistics
        cursor.execute("INSERT INTO ttl_jobs(start_time, duration) VALUES (%s, %s) RETURNING ttl_job_id", (ttl_report["ttl_start_time"], ttl_report["ttl_delete_duration"]))

        job_id = cursor.fetchone()[0]

        for attr_name, attr in ttl_report["attributes"].items():
            cursor.execute("INSERT INTO ttl_stats(att_conf_id, deleted_rows, ttl_job_id) VALUES (%s, %s, %s)", (attr["att_conf_id"], attr["ttl_rows_deleted"], job_id))

        connection.commit()
        cursor.close()

    except (Exception, psycopg2.Error) as error:
        logger.error("Error writing ttl report: {}".format(error))

        # closing database connection.
        if(connection):
            connection.close()
            logger.debug("Closed connection to server: {} due to error".format(server_config["host"]))

        return False

    connection.close()
    logger.debug("Closed connection to server: {}".format(server_config["host"]))

    return True


def process_ttl(server_config, compress_threshold_days, dryrun, processed_ttl=None):
    """
    This function opens a connection to the server and processes all ttl values in the
    att_conf table. What this means in practice is it selects all values from att_conf 
    with a valid ttl value, then runs a delete for that attributes data in its data
    table
    The processed_ttl dict is filled with the attributes that are treated
    """

    # first attempt to open a connection to the database
    try:

        connection = connect(server_config)

    except (Exception, psycopg2.Error) as error:
        logger.error("Error: {}".format(error))
        return False

    # now we have a database connection, proceed to examine each attribute and try drop any data
    # that is out of date
    try:
        cursor = connection.cursor()

        # ensure we are clustering on the composite index
        cursor.execute("SELECT att_conf_id, ttl, table_name, att_name FROM att_conf WHERE ttl IS NOT NULL AND ttl !=0")
        attributes = cursor.fetchall()
        logger.info("Fetched {} attributes with a ttl configured".format(len(attributes)))

        # get the timestamp for beginning of compression
        # We retrieve the value as a string, cause giving the value as a timstamp
        # mess with postgresql planner and the compressed chunks are scanned,
        # causing the delete operation to fail
        if compress_threshold_days > 0:
            cursor.execute("SELECT CURRENT_DATE - INTERVAL '{} days'".format(compress_threshold_days))
            timestamp = cursor.fetchall()[0][0].strftime("%a, %d %b %Y %H:%M:%S +0000")

        i = 0
        for attr in attributes:

            i += 1
            try:
                # the ttl is stored in hours, but here to keep things simple we work only in days,
                # so note how the ttl is divided by 24 and rounded up to ensure data is not removed
                # to soon.

                # also note the delete is done by counting back from midnight of yesterday, this
                # means a ttl of 1 will always at least 24 hours of data (yesterday), since today is considered
                # day 0 (or filling)
                if not dryrun:
                    if compress_threshold_days > 0:
                        cursor.execute(
                            "DELETE FROM {} WHERE data_time BETWEEN '{}' AND CURRENT_DATE - INTERVAL '{} days' AND att_conf_id = {}".format( 
                                attr[2], timestamp, math.ceil(int(attr[1]) / 24), attr[0]
                                )
                        )
                    else:
                        cursor.execute(
                            "DELETE FROM {} WHERE data_time < CURRENT_DATE - INTERVAL '{} days' AND att_conf_id = {}".format( 
                                attr[2], math.ceil(int(attr[1]) / 24), attr[0]
                                )
                        )

                    deleted_rows = cursor.rowcount

                    if processed_ttl is not None:
                        processed_ttl[attr[3]] = {"att_conf_id": attr[0], "ttl_rows_deleted": deleted_rows}

                    logger.info("{}: Deleted {} rows in table: {} for attribute: {}".format(i, deleted_rows, attr[2], attr[3]))

                else:
                    if compress_threshold_days > 0:
                        cursor.execute(
                            "SELECT COUNT(*) FROM {} WHERE data_time BETWEEN '{}' AND CURRENT_DATE - INTERVAL '{} days' AND att_conf_id = {}".format(
                                attr[2], timestamp, math.ceil(int(attr[1]) / 24), attr[0]
                            )
                        )
                    else:
                        cursor.execute(
                            "SELECT COUNT(*) FROM {} WHERE data_time < CURRENT_DATE - INTERVAL '{} days' AND att_conf_id = {}".format(
                                attr[2], math.ceil(int(attr[1]) / 24), attr[0]
                                )
                        )

                    result = cursor.fetchone()
                    logger.info("{}: {} rows would be deleted in table: {} for attribute: {}".format(i, result[0], attr[2], attr[3]))
            
            except (Exception, psycopg2.Error) as error:
                logger.error("{}: Error deleting attribute: {}".format(i, error))

        connection.commit()
        cursor.close()

    except (Exception, psycopg2.Error) as error:
        logger.error("Error deleting attributes: {}".format(error))

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

        if config is None:
            return False

        # we have a config file, validate the config
        if valid_config(config):

            # ensure all defaults met
            add_defaults_to_config(config)

            for key, val in config.items():
                start_time = datetime.datetime.now()
                start = time.monotonic()
                logger.info("Processing ttl requests for configuration: {}".format(key))
                processed_ttl = {}
                process_ttl(val["connection"], val["compress_threshold_days"], args.dryrun, processed_ttl)
                delete_time = timedelta(seconds=time.monotonic() - start)
                logger.info("Processed ttl request for configuration {} in: {}".format(key, delete_time))

                ttl_report = {"attributes": processed_ttl,
                              "ttl_delete_duration": delete_time,
                              "ttl_start_time": start_time,
                              "ttl_last_timestamp": datetime.datetime.now()}

                if not args.dryrun:
                    if val["rest_endpoint"]["enable"] is True:
                        reporting.put_dict_to_rest(
                            val["rest_endpoint"]["api_url"] +  val["rest_endpoint"]["endpoint"], ttl_report)
                    
                    if val["db_report"]["enable"] is True:
                        push_report_to_db(val["connection"], ttl_report)

        else:
            return False

    return True


def main() -> bool:
    parser = argparse.ArgumentParser(description="HDB TimscaleDb ttl service script")
    parser.add_argument("-v", "--version", action="store_true", help="version information")
    parser.add_argument("-d", "--debug", action="store_true", help="debug output for development")
    parser.add_argument("-c", "--config", default="/etc/hdb/hdbpp_ttl.conf", help="config file to use")
    parser.add_argument("--validate", action="store_true", help="validate the given config file")
    parser.add_argument("--syslog", action="store_true", help="send output to syslog")
    parser.add_argument("--dryrun", action="store_true", help="do not actually do the delete, just simulate it")
    parser.set_defaults(func=run_command)

    if len(sys.argv) == 1:
        parser.print_help(sys.stderr)
        sys.exit(1)

    args = parser.parse_args()

    stdout_formatter = logging.Formatter("%(asctime)s hdbpp-ttl[%(process)d]: %(message)s", "%Y-%m-%d %H:%M:%S")
    stdout_handler = logging.StreamHandler()
    stdout_handler.setFormatter(stdout_formatter)
    logger.addHandler(stdout_handler)

    if args.syslog:
        syslog_formatter = logging.Formatter("hdbpp-ttl[%(process)d]: %(message)s")
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
