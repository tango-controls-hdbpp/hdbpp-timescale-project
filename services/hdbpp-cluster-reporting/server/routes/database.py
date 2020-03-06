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
from server.models import Database
from flask_restplus import Resource
from flask import jsonify
from server.errors import InvalidUsage
from sqlalchemy.orm.exc import NoResultFound
from sqlalchemy.orm.exc import MultipleResultsFound


logger = logging.getLogger(config.LOGGER_NAME)

class Databases(Resource):
    def get(self):
        databases = []
        results = Database.query.with_entities(Database.name)

        for res in results:
            databases.append(res.name)
        
        return jsonify(databases)


class DatabaseSize(Resource):
    def get(self):
        try:
            result = Database.query.with_entities(Database.size).one()
            return jsonify({'size':result.size, 'unit':"bytes"})

        except NoResultFound:
            logger.error(
                    "No database defined in your system, check configuration file.")

            raise InvalidUsage("No database defined in your system, check configuration file.", 500)
        
        except MultipleResultsFound:
            logger.error(
                    "Multiple databases defined in your system, check configuration file.")

            raise InvalidUsage("Multiple databases defined in your system, check configuration file.", 500)

