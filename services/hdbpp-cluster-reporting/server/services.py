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

import logging
import atexit
from threading import Lock
import requests
from requests.exceptions import HTTPError

import psycopg2
import server.config as config

from server import db as db
from server.models import Servers
from server.models import Database
from server.models import Datatable
from server.models import Aggregate
from apscheduler.schedulers.background import BackgroundScheduler
from sqlalchemy.orm.exc import NoResultFound
from sqlalchemy.orm.exc import MultipleResultsFound
from packaging.version import parse as parse_version

logger = logging.getLogger(config.LOGGER_NAME)

scheduler = None

def update_cluster_status(configuration):
    """
    Update the status of each server in the cluster, and store it in
    the database. Any server that  can not be contacted is given an error
    or unknown status.

    Arguments:
        configuration : dict -- Server configuration
    """
    
    all_nodes_updated = False

    for host in configuration["cluster"]["hosts"]:
        role = config.SERVER_ROLE_UNKNOWN
        state = config.CONNECTION_STATE_UNKNOWN
        api_url = ""
        vers = "0.0.0"

        try:
            # First check if version has been initialiazed
            host_row = db.session.query(Servers).filter(
                                        Servers.hostname == host).one()
            
            if parse_version(host_row.version) == parse_version(vers):
                # attempt to contact the server and gets it config
                response = requests.get("http://{}:{}/patroni".format(host, configuration["cluster"]["patroni_port"]))

                # If the response was successful, no Exception will be raised
                response.raise_for_status()

                # valid response received
                if response.status_code == 200:
                    if "patroni" in response.json() and "version" in response.json()["patroni"]:
                        host_row.version = response.json()["patroni"]["version"]
                    else:
                        logger.error(
                            "Response did not contain a version for the host, please check the cluster")
            
            vers = host_row.version
        
        except NoResultFound:
            logger.error(
                    "Host {} not found in database, initialization error.".format(host))
                                
        except MultipleResultsFound:
            logger.error(
                    "Host {} is configured multiple times".format(host))

        except HTTPError as http_err:
            logger.error(
                "HTTP error occurred contacting: {}. Error: {}".format(host, http_err))

        except Exception as err:
            logger.error(
                "An error occurred contacting: {}. Error: {}".format(host, err))

        db.session.commit();

        # check for version 1.6.1, where the /cluster endpoint is implemented
        if not all_nodes_updated and parse_version(vers) > parse_version("1.6.1"):
            try:
                # attempt to contact the server cluster endpoint and retrieve the nodes
                response = requests.get("http://{}:{}/cluster".format(host, configuration["cluster"]["patroni_port"]))
                                
                # If the response was successful, no Exception will be raised
                response.raise_for_status()
 
                # valid response received
                if response.status_code == 200:
                    if "members" in response.json():
                        nodes = response.json()["members"]
                    else:
                        logger.error(
                            "Response did not contain any members in the cluster, please check the cluster")

                    # Now treat the information for all nodes.
                    if nodes is not None:
                        for node in nodes:
                            if "host" in node:
                                host = node["host"]
                            else:
                                logger.error(
                                    "Response did not contain a host, please check the cluster")

                            if "role" in node:
                                role = node["role"]
                            else:
                                logger.error(
                                    "Response did not contain a role for the host, please check the cluster")

                            if "state" in node:
                                state = node["state"]
                            else:
                                logger.error(
                                    "Response did not contain a state for the host, please check the cluster")

                            if "api_url" in node:
                                api_url = node["api_url"]
                            else:
                                logger.error(
                                    "Response did not contain the api url for the host, please check the cluster")

                            if "lag" in node and role is "replica":
                                lag = node["lag"]
                            else:
                                logger.error(
                                    "Response did not contain the lag for this replica, please check the cluster")
                            
                            if host is not None:
                                try:
                                    # if present in db update it otherwise add it
                                    server_row = db.session.query(Servers).filter(
                                        Servers.hostname == host).one()
                                    
                                    server_row.hostname = host
                                    server_row.state = state
                                    server_row.role = role
                                    server_row.lag = lag
                                    server_row.api_url = api_url
                                
                                except NoResultFound:
                                    db.session.add(Servers(host, state, role, lag, api_url))
                                
                                except MultipleResultsFound:
                                    logger.error(
                                        "Host {} is configured multiple times".format(host))

                        db.session.commit()
                        all_nodes_updated = True
            
            except HTTPError as http_err:
                logger.error(
                        "HTTP error occurred contacting: {}. Error: {}".format(host, http_err))
                
            except Exception as err:
                logger.error(
                    "An error occurred contacting: {}. Error: {}".format(host, err))

    # Retrieve the servers from the database, it has been initialized already either by conf or by the cluster query
    servers = db.session.query(Servers).all()

    for host in servers:
        role = config.SERVER_ROLE_UNKNOWN
        state = config.CONNECTION_STATE_UNKNOWN
        vers = "0.0.0"

        try:
            
            if not host.api_url:
                api_url = "http://{}:{}/patroni".format(host.hostname, configuration["cluster"]["patroni_port"])
            
            else:
                api_url = host.api_url
            
            # attempt to contact the server and gets it config
            response = requests.get(api_url)

            # If the response was successful, no Exception will be raised
            response.raise_for_status()

            # valid response received
            if response.status_code == 200:
                if "role" in response.json():
                    host.role = response.json()["role"]
                else:
                    logger.error(
                        "Response did not contain a role for the host, please check the cluster")

                if "state" in response.json():
                    host.state = response.json()["state"]
                else:
                    logger.error(
                        "Response did not contain a state for the host, please check the cluster")
                
                if "patroni" in response.json() and "version" in response.json()["patroni"]:
                    host.version = response.json()["patroni"]["version"]
                else:
                    logger.error(
                        "Response did not contain a version for the host, please check the cluster")

        except HTTPError as http_err:
            logger.error(
                "HTTP error occurred contacting: {}. Error: {}".format(host, http_err))

            host.state = config.CONNECTION_STATE_ERROR

        except Exception as err:
            logger.error(
                "An error occurred contacting: {}. Error: {}".format(host, err))

            host.state = config.CONNECTION_STATE_ERROR

        db.session.commit()

    logger.debug("Updated cluster server status with data from the cluster")

def extract_interval_rows(query_result):
    """
    From a query result containing the table name, the interval length,
    and the estimate of rows number, extract valuable information to inject
    this data into the database.
    Mainly the type and format from the table_name, and the datas in itself

    Arguments:
        query_result : tuple -- One line of the query result
    Returns:
        tuple with the str table_name, the type, the format, the interval
        and the row count.
    """
    table_name = query_result[0]
    table_name_split = table_name.split('_')
    
    if len(table_name_split) is not 3:
        return None, None, None, None, None
    
    if table_name_split[1] == "scalar":
        att_format = 'SCALAR'
    else:
        att_format = 'SPECTRUM'
    
    att_type = ('DEV_'+table_name_split[2][3:]).upper()
    
    if att_type not in config.DB_TYPES:
        return None, None, None, None, None
    
    return table_name, att_type, att_format, query_result[1], query_result[2]

def update_database_info(configuration):
    """
    Update the information on the HDB database and store it in
    the database.

    Arguments:
        configuration : dict -- Server configuration
    """

    # first attempt to open a connection to the database
    try:
        logger.debug("Attempting to connect to server: {}".format(configuration["database"]["host"]))
        # attempt to connect to the server
        connection = psycopg2.connect(
        user=configuration["database"]["user"],
            password=configuration["database"]["password"],
            host=configuration["database"]["host"],
            port=configuration["database"]["port"],
            database=configuration["database"]["database"])
        connection.autocommit = True
        logger.debug("Connected to database at server: {}".format(configuration["database"]["host"]))

    except (Exception, psycopg2.Error) as error:
        logger.error("Error: {}".format(error))
        return
    
    # now we have a database connection, proceed to get all the information we want
    try:
        cursor = connection.cursor()
        logger.debug("Fetching information about the database.")

        cursor.execute("SELECT pg_database_size('"+configuration["database"]["database"]+"');")
        database_size = cursor.fetchall()
        db.session.query(Database).filter(Database.name == configuration["database"]["database"]).update({"size":database_size[0][0]})
        db.session.commit()

        logger.debug("Fetching information about the attributes tables from the database.")

        # Retrieve all the parameters and their type.
        cursor.execute(("SELECT att_conf_type.type, att_conf_format.format, count(*) "
                        "FROM att_conf "
                        "JOIN att_conf_type ON att_conf.att_conf_type_id = att_conf_type.att_conf_type_id "
                        "JOIN att_conf_format ON att_conf.att_conf_format_id = att_conf_format.att_conf_format_id "
                        "GROUP BY att_conf_format.format, att_conf_type.type;"))
        attributes = cursor.fetchall()

        for attribute in attributes:
            logger.debug("Updating parameter type {} and format {} to count: {}".format(attribute[0],attribute[1],attribute[2]))
            db.session.query(Datatable).filter(Datatable.att_format == attribute[1], Datatable.att_type == attribute[0]).update({"att_count":attribute[2]})
        
        db.session.commit()

        # Retrieve all the tables row_count and intervals.
        cursor.execute(("SELECT h.table_name, interval_length, row_estimate "
                        "FROM _timescaledb_catalog.dimension d "
                        "LEFT JOIN _timescaledb_catalog.hypertable h ON (d.hypertable_id = h.id) "
                        "JOIN (SELECT * from hypertable_approximate_row_count()) AS t ON t.table_name = h.table_name;"))
        sizes = cursor.fetchall()
        
        for size in sizes:
            table_name, att_type, att_format, interval, rows = extract_interval_rows(size)
            
            if att_type:
                #retrieve the table size
                cursor.execute("SELECT total_bytes FROM hypertable_relation_size('"+table_name+"');")
                table_size = cursor.fetchall()[0][0]
                
                #retrieve the last chunk size for this table
                cursor.execute("SELECT total_bytes FROM chunk_relation_size('"+table_name+"') order by ranges desc limit 1;")
                chunk_size = cursor.fetchall()[0][0]
                
                logger.debug(("Updating parameter type {} and format {} to interval size: {}us"
                              "\n  Estimate number of rows: {}"
                              "\n  Table size: {}"
                              "\n  Last chunk size: {}").format(att_type, att_format, interval, rows, table_size, chunk_size))
                
                db.session.query(Datatable).filter(Datatable.att_format == att_format, Datatable.att_type == att_type) \
                        .update({"att_row_count":rows, "att_interval":interval, "att_size":table_size, "att_current_chunk_size":chunk_size})

        db.session.commit()

        # Retrieve all the aggregates row_count and sizes.
        for format_query in db.session.query(Aggregate.att_format.label('format')).distinct().all():
            
            if format_query.format == 'SCALAR':
                
                for type_query in db.session.query(Aggregate.att_type.label('type')).distinct().all():
                    
                    for interval_query in db.session.query(Aggregate.agg_interval.label('interval')).distinct().all():
                        agg_name = 'cagg_'+format_query.format.lower()+'_'+type_query.type.lower().replace('_', '')+'_'+interval_query.interval
                        
                        try:
                            cursor.execute("WITH s AS ("
                                            "SELECT materialization_hypertable AS ht "
                                            "FROM timescaledb_information.continuous_aggregates "
                                            "WHERE view_name='"+agg_name+"'::regclass"
                                        ") "
                                        "SELECT total_bytes, row_estimate "
                                        "FROM hypertable_relation_size((SELECT ht FROM s)), "
                                        "hypertable_approximate_row_count((SELECT ht FROM s));")
                        
                            sizes = cursor.fetchall()
                            for result in sizes:
                                rows = result[1]
                                agg_size = result[0]
                        
                                logger.debug(("Updating parameter type {} and format {} for interval size: {}"
                                    "\n  Estimate number of rows: {}"
                                    "\n  Table size: {}").format(type_query.type, format_query.format, interval_query.interval, rows, agg_size))
                
                                db.session.query(Aggregate).filter \
                                        (Aggregate.att_format == format_query.format, Aggregate.att_type == type_query.type, Aggregate.agg_interval == interval_query.interval) \
                                    .update({"agg_row_count":rows, "agg_size":agg_size})
                        
                        except psycopg2.Error as e:
                            # Check for errors if the database does not exist
                            if e.pgcode == '42P01':
                                logger.debug("Parameter aggregate for type {} and format {} is not present for interval {}".format(type_query.type, format_query.format, interval_query.interval))
                                
                                # then remove it from the database as it is not present
                                db.session.query(Aggregate).filter \
                                        (Aggregate.att_format == format_query.format, Aggregate.att_type == type_query.type, Aggregate.agg_interval == interval_query.interval) \
                                        .delete()

        db.session.commit()
        connection.commit()
        cursor.close()
    
    except (Exception, psycopg2.Error) as error:
        logger.error("Error retrieving all the attributes: {}".format(error))
        # closing database connection.
        if(connection):
            connection.close()
            logger.debug("Closed connection to server: {} due to error".format(configuration["database"]["host"]))
        return
    
    connection.close()
    logger.debug("Closed connection to server: {}".format(configuration["database"]["host"]))

def create_scheduler():
    global scheduler

    # create a simple background scheduler
    scheduler = BackgroundScheduler()
    scheduler.start()
    return scheduler


def init_services(configuration):

    # clear the database db
    db.session.query(Database).delete()
    db.session.commit()
    db.session.add(Database(configuration["database"]["database"]))
    db.session.commit()

    # clear the attributes db
    db.session.query(Datatable).delete()
    db.session.commit()

    # add the defaults
    for format in config.DB_FORMAT:
        for type in config.DB_TYPES:
            att = Datatable(format, type)
            db.session.add(att)
            db.session.commit()

    # clear the aggregate db
    db.session.query(Aggregate).delete()
    db.session.commit()

    # add the defaults
    for format in config.DB_FORMAT:
        # So far only scalar is supported, but keep the loop for later maybe
        if format is 'SCALAR':
            for type in config.AGG_TYPES:
                for interval in config.AGG_INTERVAL:
                    att = Aggregate(format, type, interval)
                    db.session.add(att)
                    db.session.commit()

    # clear the cluster status and reset with defaults
    db.session.query(Servers).delete()
    db.session.commit()

    # add the defaults
    for host in configuration["cluster"]["hosts"]:
        server = Servers(host)
        db.session.add(server)
        db.session.commit()

    global scheduler
    scheduler = create_scheduler()

    # shut down the scheduler when exiting the app
    atexit.register(lambda: scheduler.shutdown())

    # now schedule a job to update it at intervals
    scheduler.add_job(
        update_cluster_status,
        'interval',
        args=[configuration],
        id='servers',
        replace_existing=True,
        seconds=int(configuration["cluster"]["status_update"]))

    # now schedule a job to update the attributes information
    scheduler.add_job(
        update_database_info,
        'interval',
        args=[configuration],
        id='database',
        replace_existing=True,
        seconds=int(configuration["database"]["update_interval"]))
