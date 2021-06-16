#!/usr/bin/env python3

"""
Simple script to extract data from hdb.
"""

import os
import time as t
import sys
import argparse
import psycopg2
import yaml
import logging
import logging.handlers
import re

from cassandra.cluster import Cluster, ExecutionProfile, EXEC_PROFILE_DEFAULT
from cassandra import ConsistencyLevel
from datetime import timedelta
from datetime import date, datetime, time

logger = logging.getLogger('hdbpp-archive-integrity')

version_major = 0
version_minor = 1
version_patch = 0
debug = False

pattern = re.compile('tango://(.+:[0-9]+)/(.+)')

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
        if "timescale_connection" not in val:
            logger.error("Missing section 'timescale_connection' in config file. Please check the config file is valid")
            return False

        else:
            if "user" not in val["timescale_connection"]:
                logger.error("No user defined in 'connection' section. Please check the config file is valid")
                return False

        if "cassandra_connection" not in val:
            logger.error("Missing section 'cassandra_connection' in config file. Please check the config file is valid")
            return False
        
        else:
            if "host" not in val["cassandra_connection"]:
                logger.error("No host defined in 'cassandra_connection' section. Please check the config file is valid")
                return False

    return True

def add_defaults_to_config(config):
    """
    Ensure the defaults for certain config params are part of the configuration
    Arguments:
        config : dict -- Configuration
    """

    for _, val in config.items():
        if "password" not in val["timescale_connection"]:
            val["timescale_connection"]["password"] = ""

        if "host" not in val["timescale_connection"]:
            val["timescale_connection"]["host"] = "localhost"

        if "port" not in val["timescale_connection"]:
            val["timescale_connection"]["port"] = "5432"

        if "database" not in val["timescale_connection"]:
            val["timescale_connection"]["database"] = "hdb"

        if "keyspace" not in val["cassandra_connection"]:
            val["cassandra_connection"]["keyspace"] = "hdb"
        
        if "attr_ratio" not in val:
            val["attr_ratio"] = 50
        
        if "data_ratio" not in val:
            val["data_ratio"] = 20
        
        if "data_max" not in val:
            val["data_max"] = 5000
        
        if "tables" not in val:
            val["tables"] = ["att_scalar_devdouble"]


def load_config(path):
    """
    Load the config file from the given path
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


def extract_attributes_postgres(config):
    """
    Extract attributes from postgres database.

    Arguments:

    Returns:
        dict -- data, {attr_name:[start_time, end_time]}
    """

    ret = {}

    hdb_user = config["timescale_connection"]["user"]
    hdb_password = config["timescale_connection"]["password"]
    hdb_host = config["timescale_connection"]["host"]
    hdb_port = config["timescale_connection"]["port"]
    hdb_database = config["timescale_connection"]["database"]

    attributes_ratio = config["attr_ratio"]
    data_ratio = config["data_ratio"]
    data_max = config["data_max"]
    
    # first attempt to open a connection to the database
    try:
        logger.debug("Attempting to connect to server: {}".format(hdb_host))

        # attempt to connect to the server
        connection = psycopg2.connect(
            user=hdb_user,
            password=hdb_password,
            host=hdb_host,
            port=hdb_port,
            database=hdb_database)

        connection.autocommit = True

        logger.debug("Connected to database at server: {}".format(hdb_host))

    except (Exception, psycopg2.Error) as error:
        logger.error("Error: {}".format(error))
        return False

    # now we have a database connection, proceed to extract data.
    try:
        cursor = connection.cursor()
        logger.debug("Retrieve attributes...")
        
        for table in config["tables"]:

            # initialize the dict for the table
            ret[table] = {}
            
            # get the att_conf_id and the table where the data is from hdb
            cursor.execute("SELECT att_conf_id, att_name FROM att_conf TABLESAMPLE SYSTEM ({}) WHERE table_name='{}';".format(attributes_ratio, table))
            attrs = cursor.fetchall()

            for attr in attrs:
                # get number of records
                cursor.execute("SELECT count(*) FROM {} WHERE att_conf_id={};".format("att_scalar_devdouble", attr[0]))
                count = cursor.fetchone()[0]
                logger.debug("Attribute {} contains {} records".format(attr[0], count))
                # extract around 1000 data
                cursor.execute("select data_time, value_r FROM {} TABLESAMPLE SYSTEM ({}) WHERE att_conf_id={} LIMIT {};".format(table, data_ratio, attr[0], data_max))
                data = cursor.fetchall()
                ret[table][attr[1]]=data
                logger.debug("Added attribute {}".format(attr[0]))

        connection.commit()
        cursor.close()

    except (Exception, psycopg2.Error) as error:
        logger.error("Error extracting attributes: {}".format(error))

    if(connection):
        connection.close()
        logger.debug("Closed connection to server: {}".format(hdb_host))

    return ret

def check_attributes(attributes, config):
    """
    Check attributes from timescale against cassandra
    """
    
    cassandra_keyspace = config["cassandra_connection"]["keyspace"]
    cassandra_host = config["cassandra_connection"]["host"]

    try:
        logger.debug("Attempting to connect to server: {}".format(cassandra_host))

        profile = ExecutionProfile(
            consistency_level=ConsistencyLevel.ALL,
            )

        cluster = Cluster([cassandra_host], execution_profiles={EXEC_PROFILE_DEFAULT: profile})
        session = cluster.connect(cassandra_keyspace)
    
    except (Exception) as error:
        logger.error("Error: {}".format(error))
        return False

    for table, attrs in attributes.items():
        for attr_name, data in attrs.items():
            m = pattern.match(attr_name)
            if m:
                cs_name = m.group(1)
                attr = m.group(2)
                logger.info("Checking attribute {} from cs {}".format(attr, cs_name))
                cass_attr = session.execute("select att_conf_id, data_type from att_conf where cs_name='{}' and att_name='{}'".format(cs_name, attr))
                
                # Check that we found one and only one attribute in cassandra
                if not cass_attr:
                    logger.error("Attribute {} not found in cassandra".format(attr_name))
                else:
                    if cass_attr.one().data_type.endswith("ro"):
                        table_name = table + "_ro"
                    else:
                        table_name = table + "_rw"

#                    stmt = session.prepare("SELECT value_r FROM {} WHERE att_conf_id={} AND data_time=? AND period=?".format(table_name, cass_attr.one().att_conf_id))

                    data_count = 0
                    errors = 0
                    for dat in data:
                        data_count += 1
                        period = datetime.combine(dat[0].date(), time.min).strftime("%Y-%m-%d")
                        val = session.execute("SELECT value_r FROM {} WHERE att_conf_id={} AND data_time=%s AND period=%s".format(table_name, cass_attr.one().att_conf_id), (dat[0], period))

                        if val.one():
                            cass_val = val.one().value_r

                            if cass_val is None or dat[1] is None:
                                if cass_val is not None and cass_val != 0. and dat[1] is None:
                                    errors += 1
                                    logger.error("Error in attribute {}: expected {} found {} at {}".format(attr_name, dat[1], cass_val, dat[0]))
                            elif abs(cass_val - dat[1]) > 0.000001:
                                errors +=1
                                logger.error("Error in attribute {}: expected {} found {} at {}".format(attr_name, dat[1], cass_val, dat[0]))
                        else:
                            errors +=1
                            logger.error("Error in attribute {}: expected {} no value found at {}".format(attr_name, dat[1], cass_val, dat[0]))

                if data_count > 0:
                    logger.debug("Tested {} records with {} errors for attribute {} ({}%)".format(data_count, errors, attr_name, 100*errors/data_count))
            
            else:
                logger.error("Could not extract cs_name and attr_name from {}".format(attr_name))


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

    else:
        config = load_config(args.config)

        if config is None:
            return False

        # we have a config file, validate the config
        if valid_config(config):
            
            # ensure all defaults met
            add_defaults_to_config(config)
        
            for key, val in config.items():
                start_time = t.monotonic()
                logger.info("Comparing datasets")
        
                attributes = extract_attributes_postgres(val)

                check_attributes(attributes, val)

                compare_time = timedelta(seconds=t.monotonic() - start_time)
                logger.info("Compared databases in: {}".format(compare_time))

    return True

def main() -> bool:
    parser = argparse.ArgumentParser(description="Test data integrity from cassandra to timescale")
    parser.add_argument("-v", "--version", action="store_true", help="version information")
    parser.add_argument("-d", "--debug", action="store_true", help="debug output for development")
    parser.add_argument("-c", "--config", default="/etc/hdb/hdbpp_compare.conf", help="config file to use")
    parser.add_argument("--syslog", action="store_true", help="send output to syslog")
    parser.set_defaults(func=run_command)

    args = parser.parse_args()

    stdout_formatter = logging.Formatter("%(asctime)s hdbpp-archive-integrity[%(process)d]: %(message)s", "%Y-%m-%d %H:%M:%S")
    stdout_handler = logging.StreamHandler()
    stdout_handler.setFormatter(stdout_formatter)
    logger.addHandler(stdout_handler)

    if args.syslog:
        syslog_formatter = logging.Formatter("hdbpp-archive-integrity[%(process)d]: %(message)s")
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
