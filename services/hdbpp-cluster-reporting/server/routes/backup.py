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
import datetime
from server import db as db
from server.models import Attribute
from server.models import Database
from flask_restplus import Resource
from flask import jsonify, request
from server.errors import InvalidUsage
from sqlalchemy.orm.exc import NoResultFound
from sqlalchemy.orm.exc import MultipleResultsFound

logger = logging.getLogger(config.LOGGER_NAME)

def get_from_db(req):
    """
    Generic function that just grabs the data from the database.
    Attributes:
    -----------
    req: SQLAlchemy InstrumentedAttributes -- Output field requested.
    """
    try:
        query = Database.query.with_entities(req.label("result")).one()
            
        return jsonify(query.result)
        
    except NoResultFound:
        logger.error(
                "No database defined in your system, check configuration file.")
        raise InvalidUsage("No database defined in your system, check configuration file.", 404)

    except MultipleResultsFound:
        logger.error(
                "Multiple databases defined in your system, check configuration file.")
        raise InvalidUsage("Multiple databases defined in your system, check configuration file.", 404)
        

class Backup(Resource):
    def put(self):
        json = request.get_json()
        
        for key, val in json.items():
            try:
                database = db.session.query(Database).one()
                
                database.backup_last_id = key

                if "backup_duration" in val:
                    database.backup_duration = val["backup_duration"]
                
                if "backup_last_execution" in val:
                    database.backup_last_execution = datetime.datetime.strptime(val["backup_last_execution"], '%Y-%m-%d %H:%M:%S.%f')
            
                if "backup_size" in val:
                    database.backup_size = val["backup_size"]
                
                if "backup_error" in val:
                    database.backup_error = val["backup_error"]
            
            except NoResultFound:
                logger.error(
                    "No database defined in your system, check configuration file.")
        
            except MultipleResultsFound:
                logger.error(
                    "Multiple databases defined in your system, check configuration file.")
        
        db.session.commit()


class BackupDuration(Resource):
    def get(self):
        
        return get_from_db(Database.backup_duration)
        

class BackupLastExecution(Resource):
    def get(self):
        
        return get_from_db(Database.backup_last_execution)


class BackupId(Resource):
    def get(self):
        
        return get_from_db(Database.backup_last_id)


class BackupError(Resource):
    def get(self):
        
        return get_from_db(Database.backup_error)


class BackupSize(Resource):
    def get(self):
        
        return get_from_db(Database.backup_size)


class BackupSizeUnit(Resource):
    def get(self):
        
        return jsonify('bytes')

