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

import server.config as config
import server.models as models

from flask_restplus import Resource
from flask import jsonify, abort
from server.errors import InvalidUsage
from sqlalchemy.orm.exc import NoResultFound
from sqlalchemy.orm.exc import MultipleResultsFound
from packaging.version import parse as parse_version

logger = logging.getLogger(config.LOGGER_NAME)

# Server service and status related endpoints to allow the querying of
# the cluster or individual servers within it


class Hosts(Resource):
    def get(self):
        hosts = []
        servers_result = models.Servers.query.with_entities(models.Servers.hostname)

        for server in servers_result:
            hosts.append(server.hostname)

        return jsonify(hosts)


class Server(Resource):
    def get(self, host):
        try:
            server = models.Servers.query.filter(
                models.Servers.hostname == host).one()
a           
            lag = None
            
            if server.role != 'master' and parse_version(server.version) >= parse_version("1.6.1"):
                lag = server.lag
            
            return {"host": server.hostname, "state": server.state, "role": server.role, "lag": lag}
        
        except NoResultFound:
            logger.error("Server: {} is not known to this service".format(host))
            raise InvalidUsage("Server: {} is not known to this service".format(host))

        except MultipleResultsFound:
            logger.error("Server: {} return to many results. Unexpected error.".format(host))
            raise InvalidUsage("Server: {} return to many results. Unexpected error.".format(host))


class Servers(Resource):
    def get(self):
        servers = {"servers": []}
        servers_result = models.Servers.query.all()

        for server in servers_result:
            lag = None
            
            if server.role != 'master' and parse_version(server.version) >= parse_version("1.6.1"):
                lag = server.lag
            
            servers["servers"].append(
                    {"host": server.hostname, "state": server.state, "role": server.role, "lag": lag})

        return jsonify(servers)


class ServerRole(Resource):
    def get(self, host):
        try:
            server = models.Servers.query.filter(
                    models.Servers.hostname == host).one()
        
            return {"role": server.role}
        
        except NoResultFound:
            logger.error("Server: {} is not known to this service".format(host))
            raise InvalidUsage("Server: {} is not known to this service".format(host))

        except MultipleResultsFound:
            logger.error("Server: {} return to many results. Unexpected error.".format(host))
            raise InvalidUsage("Server: {} return to many results. Unexpected error.".format(host))


class ServerState(Resource):
    def get(self, host):
        try:
            server = models.Servers.query.filter(
                models.Servers.hostname == host).one()

            return {"state": server.state}

        except NoResultFound:
            logger.error("Server: {} is not known to this service".format(host))
            raise InvalidUsage("Server: {} is not known to this service".format(host))

        except MultipleResultsFound:
            logger.error("Server: {} return to many results. Unexpected error.".format(host))
            raise InvalidUsage("Server: {} return to many results. Unexpected error.".format(host))


class ServerLag(Resource):
    def get(self, host):
        try:
            server = models.Servers.query.filter(
                models.Servers.hostname == host).one()

            if server.role == 'master':
                logger.error("Server: {} is master, it doesn't lag".format(host))
                raise InvalidUsage("Server: {} is master, it doesn't lag".format(host))
            
            if parse_version(server.version) < parse_version("1.6.1"):
                logger.error("Server: {} version is too old {}. ({} expected)".format(host, server.version, "1.6.1"))
                raise InvalidUsage("Server: {} version is too old {}. ({} expected)".format(host, server.version, "1.6.1"))
            
            return {"state": server.lag}

        except NoResultFound:
            logger.error("Server: {} is not known to this service".format(host))
            raise InvalidUsage("Server: {} is not known to this service".format(host))

        except MultipleResultsFound:
            logger.error("Server: {} return to many results. Unexpected error.".format(host))
            raise InvalidUsage("Server: {} return to many results. Unexpected error.".format(host))
