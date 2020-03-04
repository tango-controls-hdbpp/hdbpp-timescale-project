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
This simple script reports some barman metrics for the hdbpp database project.
The script is executed through barman pre and post backup hooks. It measure the
backup time, and the size of the backup and report it to the rest api on the 
cluster reporting tool.

"""

import os
import time
import sys
import argparse
import math
import psycopg2
import yaml
import logging
import logging.handlers

import datetime
from datetime import timedelta
from hdbpp_rest_report import put_dict_to_rest

logger = logging.getLogger('hdbpp-barman-report')

version_major = 0
version_minor = 1
version_patch = 0
debug = False

start_time_file = 'start_time.log'

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
        if "hdb_api_endpoint" not in val:
            logger.error("Missing 'hdb_api_endpoint' in config file. Please check the config file is valid")
            return False

    return True


def add_defaults_to_config(config):
    """
    Ensure the defaults for certain config params are part of the configuration

    Arguments:
        config : dict -- Configuration
    """

    for _, val in config.items():
        if "hdb_api_endpoint" not in val:
            val["hdb_api_endpoint"] = 'http://hdb-services:10666/api/v1/database/backup'


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


def run_post_command(args):
    """
    Command function hooked to argparse. 

    Arguments:
        args -- Arguments from the command line

    Returns:
        bool -- True for success, False otherwise.
    """

    backup_dir = os.environ.get('BARMAN_BACKUP_DIR')

    if backup_dir:
        backups_dir = os.path.normpath(os.path.join(backup_dir, os.path.pardir))
    
    else:
        logger.error("There is no backup directory, check the barman configuration")
        return False

    error_message = os.environ.get('BARMAN_ERROR')
    backup_id = os.environ.get('BARMAN_BACKUP_ID')
    
    if args.version is True:
        print("Version {}.{}.{}".format(str(version_major), str(version_minor), str(version_patch)))
    
    else:
        config = load_config(args.config)
        
        if config is None:
            return False
        
        if args.validate is True:
            if not valid_config(config):
                return False
            
            else:                                                          
                logger.info("Config file appears to be valid")
                                                                                                                          
        barman_report = {}
        
        with open(os.path.join(backups_dir, start_time_file), "r") as fp:
            backup_time = timedelta(seconds=time.monotonic() - float(fp.read()))
        
        total_size = 0
        
        for dirpath, dirnames, filenames in os.walk(backup_dir):
            for f in filenames:
                fp = os.path.join(dirpath, f)
                
                # skip if it is symbolic link
                if not os.path.islink(fp):
                    total_size += os.path.getsize(fp)

        if backup_id:
            barman_report[backup_id] = {"backup_duration":backup_time
                    , "backup_size":total_size
                    , "backup_last_execution":datetime.datetime.now()
                    , "backup_error":error_message}
            
            put_dict_to_rest(config["hdb_api_endpoint"], barman_report)

    return True


def run_pre_command(args):
    """
    Command function hooked to argparse. 

    Arguments:
        args -- Arguments from the command line

    Returns:
        bool -- True for success, False otherwise.
    """
    
    backup_dir = os.environ.get('BARMAN_BACKUP_DIR')

    if backup_dir:
        backups_dir = os.path.normpath(os.path.join(backup_dir, os.path.pardir))
    
    else:
        logger.error("There is no backup directory, check the barman configuration")
        return False

    if args.version is True:
        print("Version {}.{}.{}".format(str(version_major), str(version_minor), str(version_patch)))

    else:
        with open(os.path.join(backups_dir, start_time_file), "w") as fp:
            fp.write(str(time.monotonic()))
    
    return True


def main() -> bool:
    parser = argparse.ArgumentParser(description="HDB TimscaleDb barman reporting service script")
    parser.add_argument("-c", "--config", default="/etc/hdb/hdbpp_barman.conf", help="config file to use")
    parser.add_argument("-v", "--version", action="store_true", help="version information")
    parser.add_argument("-d", "--debug", action="store_true", help="debug output for development")
    parser.add_argument("--validate", action="store_true", help="validate the given config file")
    parser.add_argument("--syslog", action="store_true", help="send output to syslog")
    
    phase = os.environ.get('BARMAN_PHASE')
    
    if phase:
        if phase == 'pre':
            parser.set_defaults(func=run_pre_command)
        
        elif phase == 'post':
            parser.set_defaults(func=run_post_command)
        
        else:
            logger.error("Barman is in unknown phase {}.".format(phase))
            parser.print_help(sys.stderr)
            sys.exit(1)
    
    else:
        parser.print_help(sys.stderr)
        sys.exit(1)

    args = parser.parse_args()

    stdout_formatter = logging.Formatter("%(asctime)s hdbpp-barman-report[%(process)d]: %(message)s", "%Y-%m-%d %H:%M:%S")
    stdout_handler = logging.StreamHandler()
    stdout_handler.setFormatter(stdout_formatter)
    logger.addHandler(stdout_handler)

    if args.syslog:
        syslog_formatter = logging.Formatter("hdbpp-barman-report[%(process)d]: %(message)s")
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
