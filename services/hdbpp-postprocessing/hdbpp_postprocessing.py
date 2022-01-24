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

from datetime import timedelta
from psycopg2.extras import Json

logger = logging.getLogger('hdbpp-postprocessing')

version_major = 0
version_minor = 1
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

    # return the dictionary with the configuration in for the script to use
    return config


def process_jobs(server_config):
    """
    This function opens a connection to the server and runs all the jobs defined in the
    post_processing_jobs table.
    It selects all the jobs with HDB++ postprocessing application name, runs them, and
    fill the post_processing_jobs_stats table with the needed information.
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

    # now we have a database connection, proceed to examine each attribute and try drop any data
    # that is out of date
    try:
        cursor = connection.cursor()

        # Retrieve all the jobs to be called
        cursor.execute("SELECT job_id, proc_name, config FROM postprocessing_jobs WHERE application_name='HDB++ postprocessing'")
        jobs = cursor.fetchall()
        logger.info("Fetched {} jobs to be run".format(len(jobs)))

        for job in jobs:
            
            success_count = 1
            error_count = 0
            start_time = datetime.datetime.now()
            end_time = None
            start = time.monotonic()
            
            try:

                cursor.execute(
                    "CALL {}(%s,%s)".format(
                        job[1]), [job[0], Json(job[2])]
                )

                job_status = "Job run ok"
                logger.info("Run job with job_id: {}".format(job[0]))

            except (Exception, psycopg2.Error) as error:
                logger.error("Error running postprocessing job {}: {}".format(job[0], error))
                job_status = "Job run in error"
                success_count = 0
                error_count = 1

            duration = timedelta(seconds=time.monotonic() - start)
            end_time = datetime.datetime.now()

            try:
                status = cursor.statusmessage

                cursor.execute(
                    "INSERT INTO "\
                        "postprocessing_jobs_stats("\
                            "job_id, last_run_started_at, last_successful_finish, last_run_status, "\
                            "job_status, last_run_duration, total_runs, total_successes, total_failures"\
                        ") "\
                        "VALUES("\
                            "%(id)s, %(start_time)s, %(success_end_time)s, %(run_status)s, %(status)s, %(duration)s, %(runs)s, %(success)s, %(fail)s"\
                        ")"\
                        "ON CONFLICT(job_id) DO "\
                        "UPDATE set "\
                            "last_run_started_at=EXCLUDED.last_run_started_at, "\
                            "last_successful_finish=CASE WHEN EXCLUDED.total_successes=0 THEN postprocessing_jobs_stats.last_successful_finish ELSE EXCLUDED.last_successful_finish END, "\
                            "last_run_status=EXCLUDED.last_run_status, "\
                            "job_status=EXCLUDED.job_status, "\
                            "last_run_duration=EXCLUDED.last_run_duration, "\
                            "total_runs=postprocessing_jobs_stats.total_runs + 1, "\
                            "total_successes=postprocessing_jobs_stats.total_successes + EXCLUDED.total_successes, "\
                            "total_failures=postprocessing_jobs_stats.total_failures + EXCLUDED.total_failures"\
                        ";", 
                        {
                            'id': job[0], 
                            'start_time': start_time,
                            'success_end_time': end_time,
                            'run_status': job_status,
                            'status': status,
                            'duration': duration,
                            'runs': 1,
                            'success': success_count,
                            'fail': error_count,
                        }
                    )
            except (Exception, psycopg2.Error) as error:
                logger.error("Could not report on job {} execution: {}".format(job[0], error))

        connection.commit()
        cursor.close()

    except (Exception, psycopg2.Error) as error:
        logger.error("Error running postprocessing jobs: {}".format(error))

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
                process_jobs(val["connection"])
        
        else:
            return False

    return True


def main() -> bool:
    parser = argparse.ArgumentParser(description="HDB TimscaleDb postprocessing service script")
    parser.add_argument("-v", "--version", action="store_true", help="version information")
    parser.add_argument("-d", "--debug", action="store_true", help="debug output for development")
    parser.add_argument("-c", "--config", default="/etc/hdb/hdbpp_ttl.conf", help="config file to use")
    parser.add_argument("--validate", action="store_true", help="validate the given config file")
    parser.add_argument("--syslog", action="store_true", help="send output to syslog")
    parser.set_defaults(func=run_command)

    if len(sys.argv) == 1:
        parser.print_help(sys.stderr)
        sys.exit(1)

    args = parser.parse_args()

    stdout_formatter = logging.Formatter("%(asctime)s hdbpp-postprocessing[%(process)d]: %(message)s", "%Y-%m-%d %H:%M:%S")
    stdout_handler = logging.StreamHandler()
    stdout_handler.setFormatter(stdout_formatter)
    logger.addHandler(stdout_handler)

    if args.syslog:
        syslog_formatter = logging.Formatter("hdbpp-postprocessing[%(process)d]: %(message)s")
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
