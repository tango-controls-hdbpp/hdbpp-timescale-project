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
from flask import jsonify

logger = logging.getLogger(config.LOGGER_NAME)

class Databases(Resource):
    def get(self):
        databases = []
        results = models.Database.query.with_entities(models.Database.name)
        for res in results:
            databases.append(res.name)
        return jsonify(databases)

class DatabaseSize(Resource):
    def get(self, db_name):
        result = models.Database.query.with_entities(models.Database.size).filter(models.Database.name == db_name)
        return jsonify(result[0].size)

class DatabaseSizeUnit(Resource):
    def get(self):
        return jsonify("bytes")
