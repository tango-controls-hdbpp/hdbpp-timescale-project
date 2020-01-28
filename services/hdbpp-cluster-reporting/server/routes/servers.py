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
        server = models.Servers.query.filter(
            models.Servers.hostname == host).all()

        if len(server) < 1:
            logger.error("Server: {} is not known to this service".format(server))
            abort(404)

        if len(server) > 1:
            logger.error("Server: {} return to many results. Unexpected error.".format(server))
            abort(404)

        return {"host": server[0].hostname, "state": server[0].state, "role": server[0].role}


class Servers(Resource):
    def get(self):
        servers = {"servers": []}
        servers_result = models.Servers.query.all()

        for server in servers_result:
            servers["servers"].append(
                {"host": server.hostname, "state": server.state, "role": server.role})

        return jsonify(servers)


class ServerRole(Resource):
    def get(self, host):
        server = models.Servers.query.filter(
            models.Servers.hostname == host).all()

        if len(server) < 1:
            logger.error("Server: {} is not known to this service".format(server))
            abort(404)

        if len(server) > 1:
            logger.error("Server: {} returns to many results. Unexpected error.".format(server))
            abort(404)

        return {"role": server[0].role}


class ServerState(Resource):
    def get(self, host):
        server = models.Servers.query.filter(
            models.Servers.hostname == host).all()

        if len(server) < 1:
            logger.error("Server: {} is not known to this service".format(server))
            abort(404)

        if len(server) > 1:
            logger.error("Server: {} returns to many results. Unexpected error.".format(server))
            abort(404)

        return {"state": server[0].state}
