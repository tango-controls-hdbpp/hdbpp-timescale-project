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

import os
import sys
import logging
import argparse
import yaml

import server.config as config
import server.services as services
import server.routes.status as status_endpoint
import server.routes.servers as servers_endpoint

from server import db
from flask import Flask
from flask_restplus import Api, Resource
from flask import Blueprint

logger = logging.getLogger(config.LOGGER_NAME)


def parse_args():
    """
    Parse the script arguments to perform any setup for the process
    """

    parser = argparse.ArgumentParser(description="HDB TimscaleDb Service Server")
    parser.add_argument("-d", "--debug", action="store_true", help="debug output for development")
    parser.add_argument("-c", "--config", default="/etc/hdb/db_services.conf", help="config file to load and configure the server with")
    parser.add_argument("--validate", action="store_true", help="validate the config file and do not run the server")
    parser.add_argument("--syslog", action="store_true", help="send output to syslog")
    parser.add_argument("--devel", action="store_true", help="run with development configuration")
    args = parser.parse_args()

    return args


def validate_config(configuration):
    """
    Validate the yaml config. Certain values will be checked for, and if not present
    the config is considered not valid and false is returned

    Arguments:
        configuration : dict -- dictionary of values that represent the config. Loaded from yaml

    Returns:
        bool -- True on success, False otherwise
    """

    if len(configuration) == 0:
        logger.error("Invalid config file, no values loaded. Please check the config file is valid")
        return False

    if "cluster" not in configuration:
        logger.error("Missing section 'cluster' in config file. Please check the config file is valid")
        return False

    if "hosts" not in configuration["cluster"]:
        logger.error("Missing section 'hosts' subsection 'cluster' in config file. Please check the config file is valid")
        return False

    if len(configuration["cluster"]["hosts"]) == 0:
        logger.error("No hosts defined in 'hosts' subsection in config file. Please check the config file is valid")
        return False

    return True


def load_config(config_file):
    """
    Load the config file from the given config_file

    Arguments:
        config_file : str -- Path and name of the config file to load

    Returns:
        dict -- dictionary of values from the yaml config file. 
    """

    with open(config_file, 'r') as fp:
        try:
            config = yaml.safe_load(fp)

        except yaml.YAMLError as error:
            logger.error("Unable to load the config file: {}. Error: {}".format(config_file, error))
            return None

    logger.info("Loaded config file: {}".format(config_file))

    # return the dictionary for the script to use
    return config

def set_config_defaults(configuration):
    """
    Set any missing configuration values to defaults

    Arguments:
        configuration : dict -- Configuration values from config file
    """    

    if "listen_on" not in configuration["general"]:
        configuration["general"]["listen_on"] = 10666

    if configuration["general"]["listen_on"] == None:
        configuration["general"]["listen_on"] = 10666

    if "status_update" not in configuration["cluster"]:
        configuration["cluster"]["status_update"] = 5

    if configuration["cluster"]["status_update"] == None:
        configuration["cluster"]["status_update"] = 5

    if "patroni_port" not in configuration["cluster"]:
        configuration["cluster"]["patroni_port"] = 8008
    
    if configuration["cluster"]["patroni_port"] == None:
        configuration["cluster"]["patroni_port"] = 8008

def config_logging(args):
    """
    Configure the logging system based on the args
    """

    stdout_formatter = logging.Formatter("%(asctime)s hdbpp-cluster-reporting[%(process)d]: %(message)s", "%Y-%m-%d %H:%M:%S")
    stdout_handler = logging.StreamHandler()
    stdout_handler.setFormatter(stdout_formatter)
    logger.addHandler(stdout_handler)

    if args.syslog:
        syslog_formatter = logging.Formatter('hdbpp-cluster-reporting[%(process)d]: %(message)s')
        syslog_handler = logging.handlers.SysLogHandler(address='/dev/log')
        syslog_handler.setFormatter(syslog_formatter)
        logger.addHandler(syslog_handler)

    if args.debug:
        logger.setLevel(logging.DEBUG)
    else:
        logger.setLevel(logging.INFO)


def create_app(config_name):
    """
    Create the flask app and return it

    Arguments:
        config_name : str -- Name of the configuration to start with

    Returns:
        Flask -- The flask app
    """

    # start flask with blueprints
    blueprint = Blueprint('api', __name__)
    api = Api(blueprint)

    app = Flask(__name__)
    app.config.from_object(config.config_by_name[config_name])
    app.app_context().push()

    app.register_blueprint(blueprint, url_prefix='/api/v1')

    # create the routes
    api.add_resource(status_endpoint.ServerHealth, '/health/servers')
    api.add_resource(servers_endpoint.Servers, '/servers')
    api.add_resource(servers_endpoint.Hosts, '/servers/hosts')
    api.add_resource(servers_endpoint.Server, '/servers/server/<string:host>')
    api.add_resource(servers_endpoint.ServerState, '/servers/server/state/<string:host>')
    api.add_resource(servers_endpoint.ServerRole, '/servers/server/role/<string:host>')

    return app


def main():

    # process the command line first, then run the setup for the application
    args = parse_args()
    config_logging(args)

    if not os.path.isfile(args.config):
        logger.error("The configuration file: {} does not exist. Unable to run.".format(args.config))

    # config file validation request, so just run that and exit
    if args.validate:
        validate_config(load_config(args.config))
        return True

    else:
        # run the startup routines, such as config loading, this should
        # return a configuration if the given arguments are valid
        configuration = load_config(args.config)

        # we have a config file, validate the config
        if not validate_config(configuration):
            return False

        # set defaults that are missing
        set_config_defaults(configuration)

    mode = "prod"

    if args.devel:
        mode = "dev"

    print(mode)

    # now create the flask app
    app = create_app(mode)

    from server.models import Servers
    db.app = app
    db.init_app(app)
    db.create_all()
    db.session.commit()

    # setup services
    services.init_services(configuration)

    # finally run the app
    app.run(host="0.0.0.0", port=int(configuration["general"]["listen_on"]), debug=True, use_reloader=False)
