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
Simple script to parse a cassandra csv dump and import it to timescaledb.

The script is configured with a simple yaml style config file.
"""

import os
import os.path
import time
import sys
import argparse
import logging
import logging.handlers
import json
import traceback
import csv

from datetime import datetime
from datetime import timedelta
from multiprocessing import Process, Manager
import psycopg2
from psycopg2.extras import execute_values
import yaml


logger = logging.getLogger('hdbpp-import')

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

    if "csv_file" not in config:
        logger.error("Missing entry 'csv_file' in config file. Please check the config file is valid")
        return False

    for _, val in config.items():
        if _ == "hdb_cluster":
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
        if _ == "hdb-cluster":
            if "password" not in val["connection"]:
                val["connection"]["password"] = "password"

            if "host" not in val["connection"]:
                val["connection"]["host"] = "vm-hdb-test"

            if "port" not in val["connection"]:
                val["connection"]["port"] = "5432"

            if "database" not in val["connection"]:
                val["connection"]["database"] = "hdb"
    
    if "export_data" not in config:
        config["export_data"] = False

    if "output_dir" not in config:
        config["output_dir"] = "."


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


def get_format_id(table_name):
    """
    Returns the format_id as per timescaledb schema based on the table name.
    """

    if "scalar" in table_name:
        return 1

    if "array" in table_name:
        return 2

    return 3


def get_write_id(table_name):
    """
    Returns the write_id as per timescaledb schema based on the table name.
    """

    if "ro" in table_name:
        return 1

    if "rw" in table_name:
        return 4

    return 3


def get_type_id(table_name):
    """
    Returns the type_id as per timescaledb schema based on the table name.
    """

    if "boolean" in table_name:
        return 1

    if "short" in table_name:
        if "ushort" in table_name:
            return 6

        return 2

    if "long" in table_name:
        if "long64" in table_name:
            if "ulong64" in table_name:
                return 12

            return 11

        if "ulong" in table_name:
            return 7

        return 3

    if "float" in table_name:
        return 4

    if "double" in table_name:
        return 5

    if "string" in table_name:
        return 8

    if "state" in table_name:
        return 9

    if "uchar" in table_name:
        return 10

    if "enum" in table_name:
        return 14

    if "encoded" in table_name:
        return 13

    return 0


def replace_array_bracket(val):
    """
    In csv files the array is inbetween [], but postgresql expect {} for arrays.
    Replace the first by the latter.
    """
    if val and val.startswith("[") and val.endswith("]"):
        val = "{" + val[1:-1] + "}"

    return val


def fix_array_escaping(values):
    """
    There are some issues with escape characters
    that sometimes lead to wrong values being found
    try to fix it.
    """

    tmp = []
    idx = 0
    previous_val = False
    while idx < len(values):
        
        if values[idx].startswith("[") and not values[idx].endswith("]"):
            if not previous_val:
                new_val = values[idx]
            else:
                idx -= 1
            
            for i in range(idx + 1, len(values)):
                new_val += "," + values[i]
                
                if "]" in values[i]:
                    tmp.append(fix_escaping(new_val[:new_val.find("]") + 1]))
                    idx = i
                    
                    previous_val = "[" in values[i] 
                    new_val = new_val[new_val.find("["):]
                    break
        else:
            tmp.append(values[idx])
        
        idx += 1

    return tmp


def fix_escaping(value):
    """
    In case there was a problem with escaping
    it is most likely that the string is filled with \ or " char
    so try to make it better
    """
    val = value.replace("\\", "")
    val = val.replace("\"", "")

    return val

def import_att_conf(server_config, att_conf_file, id_table):
    """
    Parse att_conf file and import the data into the base
    if it was not done already.
    On insertion extract a corresponding id so that an
    attribute can be identified.

    Arguments:
        server_config: dict: db connection info
        att_conf_file: str: path to the att_conf csv file.
        id_table: dict: contains the correspondance between
        cassandra and timescale ids.
    """
    connection = db_connect(server_config["user"], server_config["password"], server_config["host"], server_config["port"], server_config["database"])

    if(connection):
        cursor = connection.cursor()

        try:
            start_time = time.monotonic()
            logger.debug("Starting to parse {}.".format(att_conf_file))
            csv_handle = open(att_conf_file, 'r')
            csv_r = csv.reader(csv_handle)
            new_data = False

            for csvalues in csv_r:
                # extract conf values from att_conf table
                cs_name = csvalues[0]
                att_name = "tango://{}/{}".format(cs_name, csvalues[1])
                att_id = csvalues[2]
                table_name_raw = csvalues[3]
                ttl = csvalues[4]

                if not ttl:
                    ttl = 0

                format_id = get_format_id(table_name_raw)
                write_id = get_write_id(table_name_raw)
                type_id = get_type_id(table_name_raw)
                file_name = "att_{}.csv".format(table_name_raw)
                table_name = "att_{}".format(table_name_raw[:-3])

                if table_name not in id_table or (table_name in id_table and att_id not in id_table[table_name]):
                    logger.debug("Running SQL command:\n" \
                            "INSERT INTO att_conf (att_name, att_conf_type_id, att_conf_format_id, att_conf_write_id, table_name, cs_name, ttl) VALUES ({}, {}, {}, {}, {}, {}, {}) RETURNING att_conf_id;" \
                            .format(att_name, type_id, format_id, write_id, table_name, cs_name, ttl))
                 # Insert the attribute into hdb
                    cursor.execute( \
                            ("INSERT INTO att_conf (att_name, att_conf_type_id, att_conf_format_id, att_conf_write_id, table_name, cs_name, ttl) "
                                "VALUES (%s, %s, %s, %s, %s, %s, %s) "
                                "ON CONFLICT(att_name) DO UPDATE SET att_name=EXCLUDED.att_name "
                                "RETURNING att_conf_id;") \
                                            , (att_name, type_id, format_id, write_id, table_name, cs_name, ttl))

                    new_id = cursor.fetchone()

                    if table_name not in id_table:
                        id_table[table_name] = {}

                    id_table[table_name][att_id] = new_id[0]
                    new_data = True

            logger.info("Parsing done in {}s".format(timedelta(seconds=time.monotonic() - start_time)))
            if new_data:
                logger.debug("Dumping inserted ids to ids.json.")

            with open('ids.json', 'w') as file_handle:
                json.dump(id_table, file_handle)

        except (Exception, psycopg2.Error) as error:
            logger.error("Error importing att_conf data: {}".format(error))
            traceback.print_exc()
            print(error)

            # closing database connection.
            if(connection):
                connection.close()
                logger.debug("Closed connection to server: {} due to error".format(server_config["host"]))

        if(connection):
            connection.close()
            logger.debug("Closed connection to server: {}".format(server_config["host"]))


def db_connect(user, password, host, port, db):
    """
    Initialize db connection
    """
    # Attempt to open a connection to the database
    try:
        logger.debug("Attempting to connect to server: {}".format(host))

        # attempt to connect to the server
        connection = psycopg2.connect(
                user=user,
                password=password,
                host=host,
                port=port,
                database=db)

        connection.autocommit = True

        logger.debug("Connected to database at server: {}".format(host))

        return connection

    except (Exception, psycopg2.Error) as error:
        logger.error("Error: {}".format(error))
        return None

def push_data_to_db(server_config, connection, cursor, table_name, insert_values, insert_error_values):
    """
    Effectively push a bunch of data to the db.
    Arguments:
        server_config, dict: connection info, in case something happen and a new connection has
        to be initialized.
        cursor: current cursor to use for the connection.
        insert_values, list: array of the values to push.
        insert_error_values, list: array of the values with an error to push.
    Return:
        tuple connection, cursor: in case of a connection problem, return the updated values.
    """
    try:
        if len(insert_values) > 1000:
            execute_values(cursor, \
                    "INSERT INTO {} (att_conf_id, data_time, value_r, value_w, quality) VALUES %s ON CONFLICT DO NOTHING".format(table_name) \
                    , insert_values)
            insert_values.clear()
                
        if len(insert_error_values) > 1000:
            execute_values(cursor, \
                    "INSERT INTO {} (att_conf_id, data_time, value_r, value_w, quality, att_error_desc_id) VALUES %s ON CONFLICT DO NOTHING".format(table_name) \
                    , insert_error_values)
            insert_error_values.clear()
            
    except psycopg2.InterfaceError as ex:
        connection = db_connect(server_config["user"], server_config["password"], server_config["host"], server_config["port"], server_config["database"])
                
        if connection:
            cursor = connection.cursor()
            
    except (Exception, psycopg2.Error) as e:
        if "duplicate key" not in "{}".format(e):
            print(traceback.format_exc())
            logger.error("An error occured while importing data:\n{}".format(e))
    
    return (connection, cursor)

def import_data_worker(server_config, table_name, path, dsbulk_export, id_table, offset, error_dict, export_data, output_dir):
    """
    Worker to process a file and push it to the database.
    """
    connection = db_connect(server_config["user"], server_config["password"], server_config["host"], server_config["port"], server_config["database"])
    
    if connection:
        cursor = connection.cursor()

        start_time = time.monotonic()
        
        logger.info("Starting to insert {}".format(path))
        insert_values = []
        insert_error_values = []

        data_file = open(path, 'r')
        csv_reader = csv.reader(data_file, escapechar='\\')

        for datavals in csv_reader:

            error_d = None

            datavals = fix_array_escaping(datavals)

            # Retrieve the timescaledb id
            try:
                new_id = id_table[table_name][datavals[0]]

            except KeyError:
                new_id = None
                logger.debug("Found key {} in data but it is not registered.".format(datavals[0]))

            if new_id is not None:
                try:
                    if dsbulk_export:
                        data_time = datetime.strptime(datavals[2], "%Y-%m-%dT%H:%M:%SZ")
                    else:
                        data_time = datetime.strptime(datavals[2], "%Y-%m-%d %H:%M:%S.%f%z")
                            
                    if len(datavals) > 10+offset and datavals[10 + offset]:
                        value_r = datavals[10 + offset]
                    else:
                        value_r = None

                    value_w = None
                    if len(datavals) > 11 + offset and datavals[11 + offset]:
                        value_w = datavals[11 + offset]

                    else:
                        value_w = None

                    if(offset > 0):
                        value_r = replace_array_bracket(value_r)
                        value_w = replace_array_bracket(value_w)
                    if datavals[7 + offset]:
                        quality = datavals[7 + offset]
                    else:
                        quality = None

                    error_id = None
                    if datavals[4 + offset] is not None and datavals[4 + offset]:
                        # In case of comma in the error we already removed the double quotes
                        if not error_d:
                            if datavals[4 + offset].startswith('"') and datavals[4 + offset].endswith('"'):
                                error_d = datavals[4 + offset][1:-1]
                            else:
                                error_d = datavals[4 + offset]

                        error_d = error_d.replace("\\n", "\n")

                        # Check if the error is already registered
                        if error_d not in error_dict:
                            # An error occurred keep it.
                            cursor.execute(("INSERT INTO att_error_desc (error_desc) VALUES (%s)"
                                "ON CONFLICT(error_desc) DO UPDATE SET error_desc=EXCLUDED.error_desc"
                                " RETURNING att_error_desc_id;"), (error_d,))

                            error_dict[error_d] = cursor.fetchone()[0]

                        error_id = error_dict[error_d]
                        insert_error_values.append((new_id, data_time, value_r, value_w, quality, error_id))

                    else: 
                        insert_values.append((new_id, data_time, value_r, value_w, quality))
                        
                except (Exception, psycopg2.Error) as e:
                    # Does it still happen ?
                    if "duplicate key" not in "{}".format(e):
                        print(datavals)
                        print(traceback.format_exc())
                        logger.error("An error occured while importing: {}\n{}".format(datavals, e))

                if export_data:
                    res = []
                            
                    with open("{}/{}_out.csv".format(output_dir, table_name), "w") as f:
                        res.append(new_id)
                        res.append(datavals[2])

                        if value_r:
                            res.append(value_r)
                        else:
                            res.append("\\N")
                        if value_w:
                            res.append(value_w)
                        else:
                            res.append("\\N")
                        if quality:
                            res.append(quality)
                        else:
                            res.append("\\N")
                        if error_id:
                            res.append(error_id)
                        else:
                            res.append("\\N")
                        res.append("\\N")

                        f.write('\t'.join(str(x) for x in res) + '\n')
                    
            (connection, cursor) = push_data_to_db(server_config, connection, cursor, table_name, insert_values, insert_error_values)
        
        (connection, cursor) = push_data_to_db(server_config, connection, cursor, table_name, insert_values, insert_error_values)

        connection.commit()
        cursor.close()

        logger.debug("Inserting data took: {}".format(timedelta(seconds=time.monotonic() - start_time)))
        connection.close()

    logger.debug("Closed connection to server: {}".format(server_config["host"]))


def init_error_dict(server_config):
    """
    Initialize the error to id dictionnary with values in the db.
    TODO
    """
    return []


def import_data(csv_file, server_config, output_dir, export_data, id_table):
    """
    Import data from a csv_file to the given server config. 
    This function will open a connection, perform the action then
    close the connection.

    Arguments:
        csv_file : str -- path for the input csv_file
        server_config : dict -- dictionary of values from the config file that defines the server
        output_dir : str -- path for the output csv data if exporting data
        export_data : bool -- True to export data to csv file
        id_table : dict -- corresponding table for old ids to new ones for already imported data

    Returns:
        bool -- True on success, False otherwise
    """

    # import the data from att_conf if needed.
    import_att_conf(server_config, csv_file, id_table)
    
    # determine data directory
    dirname = os.path.dirname(os.path.abspath(csv_file))
    
    with Manager() as manager:
        # Initialize the error dictionnary
        error_dict = manager.dict(init_error_dict(server_config))
        processes = []
        
        for table_name in id_table:
            offset = 0

            # if this is an array, there are 2 more cols
            if "array" in table_name:
                offset = 2

            for ext in ["_ro.csv", "_rw.csv"]:

                # Now export the data to a compatible csv file
                data_path = os.path.join(dirname, "{}{}".format(table_name, ext))

                if not os.path.exists(data_path):
                    logger.debug("Data dump {}{} not found.".format(table_name, ext))
                    continue

    #                    if "array_devdouble_rw" not in data_path:
    #                        continue

                else:
                    # We register if the export was done through dsbulk, timestamp format is different then
                    if os.path.isdir(data_path):
                        dsbulk_export = True
                        data_files = [os.path.join(data_path, "{}".format(x)) for x in  os.listdir(data_path)]
                    else:
                        dsbulk_export = False
                        data_files = [data_path]

                for path in data_files:
                    import_process = Process(target=import_data_worker, args=(server_config, table_name, path, dsbulk_export, id_table, offset, error_dict, export_data, output_dir))
                    import_process.start()
                    processes.append(import_process)
            
        for process in processes:
            process.join()

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

            # config is valid, now check and add defaults where required
            add_defaults_to_config(config)

            # now reorder the tables with the given config for
            # each root entry in the config file
            for key, val in config.items():
                if key == "hdb-cluster":
                    try:
                        id_table = json.load(open(args.ids, 'r'))
                    except (OSError):
                        id_table = {}

                    start_time = time.monotonic()
                    logger.info("Import data to: {}".format(key))

                    import_data(config["csv_file"], val["connection"], config["output_dir"], config["export_data"], id_table)

                    logger.info("Imported data to {} in: {}".format(key, timedelta(seconds=time.monotonic() - start_time)))

        else:
            return False

    return True


def main() -> bool:
    parser = argparse.ArgumentParser(description="HDB Cassandra to TimscaleDb import service script")
    parser.add_argument("-v", "--version", action="store_true", help="version information")
    parser.add_argument("-d", "--debug", action="store_true", help="debug output for development")
    parser.add_argument("-c", "--config", default="/etc/hdb/import.conf", help="config file to use")
    parser.add_argument("-i", "--ids", default="ids.json", help="Correspondance table for old ids to new ones in json format")
    parser.add_argument("--validate", action="store_true", help="validate the given config file")
    parser.add_argument("--syslog", action="store_true", help="send output to syslog")
    parser.set_defaults(func=run_command)

    if len(sys.argv) == 1:
        parser.print_help(sys.stderr)
        sys.exit(1)

    args = parser.parse_args()

    stdout_formatter = logging.Formatter("%(asctime)s hdbpp-import[%(process)d]: %(message)s", "%Y-%m-%d %H:%M:%S")
    stdout_handler = logging.StreamHandler()
    stdout_handler.setFormatter(stdout_formatter)
    logger.addHandler(stdout_handler)

    if args.syslog:
        syslog_formatter = logging.Formatter("hdbpp-import[%(process)d]: %(message)s")
        syslog_handler = logging.handlers.SysLogHandler(address='/dev/log')
        syslog_handler.setFormatter(syslog_formatter)
        logger.addHandler(syslog_handler)

    if args.debug or debug:
        logger.setLevel(logging.DEBUG)
    else:
        logger.setLevel(logging.INFO)

    return args.func(args)


if __name__ == "__main__":
    result = main()

    if result is not True:
        logger.error("Command failed\n")
