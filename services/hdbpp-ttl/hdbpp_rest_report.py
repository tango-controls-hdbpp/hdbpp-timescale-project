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
This simple script defines some helper methods to send the result of the ttl to a rest
server instance of the cluster reporting.

It can be called directly from another script, providing the rest api address, the
endpoint to reach and the data to be transferred as a dict to be converted to json.
Or it can be run as standalone providing all the necessary information to the command
line, this mode is mostly for testing.
"""

import os
import time
import sys
import argparse
import math
import yaml
import logging
import logging.handlers
import requests
import json

from datetime import timedelta

logger = logging.getLogger('hdbpp-rest-report')

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

    if "api_url" not in config:
        logger.error("Missing element 'api_url' in config file. Please check the config file is valid")
        return False

    if "endpoint" not in config:
        logger.error("Missing element 'endpoint' in config file. Please check the config file is valid")
        return False
    
    if "json_message" not in config and "json_file" not in config:
        logger.error("No message to send, please provide 'json_message' or 'json_file'. Please check the config file is valid")
        return False

    return True


def add_defaults_to_config(config):
    """
    Ensure the defaults for certain config params are part of the configuration

    Arguments:
        config : dict -- Configuration
    """

    if "api_url" not in config:
        config["api_url"] = "http://localhost:10666/api/v1"
    
    if "endpoint" not in config:
        config["endpoint"] = "/database/ttl/attributes"
    
    if "json_message" not in config and "json_file" not in config:
        config["json_message"] = "{}"


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


def post_dict_to_rest(api_endpoint, json_data):
    """
    This function opens a connection to the rest server and
    send a POST message with the json_data 
    """

    # We are sending json so set the header properly
    header = {"Content-Type" : "application/json"}


    # send the data
    answer = requests.post(api_endpoint, data=json.dumps(json_data), headers=header)
    
    try:
        answer.raise_for_status()
    
    except HTTPError as e:
        logger.error("An error occured while sending the post request: {}".format(e))
        return False
    
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
            start_time = time.monotonic()
            logger.info("Processing rest post report for configuration: {}".format(config))
            message = {}
            
            if "json_message" in config:
                message = json.loads(config["json_message"])
            
            else:
                with open(config["json_file"], 'r') as fp:
                    message = json.load(fp)
            
            post_dict_to_rest(config["api_url"]+config["endpoint"], message)
            send_time = timedelta(seconds=time.monotonic() - start_time)
            logger.info("Processed rest post report for configuration {} in: {}".format(config, send_time))

        else:
            return False

    return True


def main() -> bool:
    parser = argparse.ArgumentParser(description="HDB TimscaleDb rest report service script")
    parser.add_argument("-v", "--version", action="store_true", help="version information")
    parser.add_argument("-d", "--debug", action="store_true", help="debug output for development")
    parser.add_argument("-c", "--config", default="", help="config file to use")
    parser.add_argument("--validate", action="store_true", help="validate the given config file")
    parser.add_argument("--syslog", action="store_true", help="send output to syslog")
    parser.set_defaults(func=run_command)

    if len(sys.argv) == 1:
        parser.print_help(sys.stderr)
        sys.exit(1)

    args = parser.parse_args()

    stdout_formatter = logging.Formatter("%(asctime)s hdbpp-rest-report[%(process)d]: %(message)s", "%Y-%m-%d %H:%M:%S")
    stdout_handler = logging.StreamHandler()
    stdout_handler.setFormatter(stdout_formatter)
    logger.addHandler(stdout_handler)

    if args.syslog:
        syslog_formatter = logging.Formatter("hdbpp-rest-report[%(process)d]: %(message)s")
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
