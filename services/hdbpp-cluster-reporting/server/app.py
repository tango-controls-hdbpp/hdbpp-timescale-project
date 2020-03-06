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
import logging
import argparse
import yaml

import server.config as config
import server.services as services
import server.routes.servers as servers_endpoint
import server.routes.attributes as attributes_endpoint
import server.routes.aggregates as aggregates_endpoint
import server.routes.database as database_endpoint
import server.routes.ttl as ttl_endpoint
import server.routes.backup as backup_endpoint

from server.errors import InvalidUsage
from server.errors import handle_error 
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

    if configuration["database"]["user"] == None:
        configuration["database"]["user"] = "postgres"

    if configuration["database"]["password"] == None:
        configuration["database"]["password"] = "password"
    
    if configuration["database"]["port"] == None:
        configuration["database"]["port"] = 5432
    
    if configuration["database"]["database"] == None:
        configuration["database"]["database"] = "hdb"
    
    if configuration["database"]["update_interval"] == None:
        configuration["database"]["update_interval"] = 600

    if not configuration["limits"]:
        configuration["limits"] = {}

    if not configuration["limits"]["error"]:
        configuration["limits"]["error"] = '40G'

    if not configuration["limits"]["warning"]:
        configuration["limits"]["warning"] = '20G'


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

def set_cors_headers(response):
    header = response.headers
    header['Access-Control-Allow-Origin'] = '*'
    return response

def create_app(config_name, configuration):
    """
    Create the flask app and return it

    Arguments:
        config_name : str -- Name of the configuration to start with

    Returns:
        Flask -- The flask app
    """

    # start flask with blueprints
    blueprint = Blueprint('api', __name__)
    blueprint.after_request(set_cors_headers)
    api = Api(blueprint)

    app = Flask(__name__)
    app.config.from_object(config.config_by_name[config_name])
    app.app_context().push()

    app.register_error_handler(InvalidUsage, handle_error)

    app.register_blueprint(blueprint, url_prefix='/api/v1')

    # Retrieve the warning and error levels from the configuration
    levels = {'error': configuration['limits']['error'], 'warning':configuration['limits']['warning']}

    # create the routes
    api.add_resource(servers_endpoint.Health, '/health/servers')
    api.add_resource(servers_endpoint.Servers, '/servers')
    api.add_resource(servers_endpoint.Hosts, '/servers/hosts')
    api.add_resource(servers_endpoint.Server, '/servers/server/<string:host>')
    api.add_resource(servers_endpoint.ServerState, '/servers/server/state/<string:host>')
    api.add_resource(servers_endpoint.ServerRole, '/servers/server/role/<string:host>')
    api.add_resource(servers_endpoint.ServerLag, '/servers/server/lag/<string:host>')

    api.add_resource(attributes_endpoint.AttributesType, '/database/attributes/type')
    api.add_resource(attributes_endpoint.AttributesFormat, '/database/attributes/format')
    api.add_resource(attributes_endpoint.AttributesCount, '/database/attributes/count')
    api.add_resource(attributes_endpoint.AttributesTypeOrFormatCount, '/database/attributes/count/<string:att_info>')
    api.add_resource(attributes_endpoint.AttributesFormatTypeCount, '/database/attributes/count/<string:att_format>/<string:att_type>')
    
    api.add_resource(ttl_endpoint.Health, '/health/database/ttl')
    api.add_resource(ttl_endpoint.Ttl, '/database/ttl')
    api.add_resource(ttl_endpoint.TtlLastExecution, '/database/ttl/last_execution')
    api.add_resource(ttl_endpoint.TtlDuration, '/database/ttl/duration')
    api.add_resource(ttl_endpoint.Attributes, '/database/ttl/attributes')
    api.add_resource(ttl_endpoint.AttributeRowDeleted, '/database/ttl/daily_rows_deleted/<string:att_name>')
    
    api.add_resource(attributes_endpoint.Health, '/health/database/tables', resource_class_kwargs=levels)
    api.add_resource(attributes_endpoint.Attributes, '/database/tables')
    api.add_resource(attributes_endpoint.AttributesRowCount, '/database/tables/row_count/<string:att_format>/<string:att_type>')
    api.add_resource(attributes_endpoint.AttributesInterval, '/database/tables/interval/<string:att_format>/<string:att_type>')
    api.add_resource(attributes_endpoint.AttributesSize, '/database/tables/size/<string:att_format>/<string:att_type>')
    api.add_resource(attributes_endpoint.AttributesCurrentSize, '/database/tables/current_size/<string:att_format>/<string:att_type>')
    
    api.add_resource(aggregates_endpoint.Aggregates, '/database/aggregates')
    api.add_resource(aggregates_endpoint.AggregatesRowCount, '/database/aggregates/row_count/<string:att_type>/<string:agg_interval>')
    api.add_resource(aggregates_endpoint.AggregatesSize, '/database/aggregates/size/<string:att_type>/<string:agg_interval>')

    api.add_resource(database_endpoint.Databases, '/databases')
    api.add_resource(database_endpoint.DatabaseSize, '/database/size')

    api.add_resource(backup_endpoint.Health, '/health/database/backup')
    api.add_resource(backup_endpoint.Backup, '/database/backup')
    api.add_resource(backup_endpoint.BackupLastExecution, '/database/backup/last_execution')
    api.add_resource(backup_endpoint.BackupDuration, '/database/backup/duration')
    api.add_resource(backup_endpoint.BackupId, '/database/backup/last_id')
    api.add_resource(backup_endpoint.BackupSize, '/database/backup/size')
    api.add_resource(backup_endpoint.BackupError, '/database/backup/error')
    
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
    app = create_app(mode, configuration)

    from server.models import Servers
    from server.models import Datatable
    from server.models import Database
    from server.models import Aggregate
    from server.models import Attribute
    db.app = app
    db.init_app(app)
    db.create_all()
    db.session.commit()

    # setup services
    services.init_services(configuration)

    # finally run the app
    app.run(host="0.0.0.0", port=int(configuration["general"]["listen_on"]), debug=True, use_reloader=False)
