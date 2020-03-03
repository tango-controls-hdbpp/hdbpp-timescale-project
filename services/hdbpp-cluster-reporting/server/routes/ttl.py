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

NO_DATABASE_ERROR="No database defined in your system, check configuration file."
MULTIPLE_DATABASE_ERROR="Multiple databases defined in your system, check configuration file."

class Attributes(Resource):
    def get(self):
        attributes = []
        results = Attribute.query.with_entities(Attribute.name)

        for res in results:
            attributes.append(res.name)
        
        return jsonify(attributes)


class Ttl(Resource):
    def put(self):
        json = request.get_json()

        attributes = db.session.query(Attribute).all()
        
        for attribute in attributes:
            if "attributes" in json and attribute.name in json["attributes"]:
                if "ttl_rows_deleted" in json["attributes"][attribute.name]:
                    attribute.ttl_rows_deleted = json["attributes"][attribute.name]["ttl_rows_deleted"]
                    json["attributes"].pop(attribute.name, None)
            
            else:
                attribute.ttl_rows_deleted = None
        
        if "attributes" in json:
            for attribute, att_info in json["attributes"].items():
                if "ttl_rows_deleted" in att_info:
                    db.session.add(Attribute(attribute, att_info["ttl_rows_deleted"]))
        
        db.session.commit()

        if "ttl_duration" in json or "ttl_last_execution" in json:
            try:
                database = db.session.query(Database).one()
                
                if "ttl_duration" in json:
                    database.ttl_duration = json["ttl_duration"]
                
                if "ttl_last_execution" in json:
                    database.ttl_last_execution = datetime.datetime.strptime(json["ttl_last_execution"], '%Y-%m-%d %H:%M:%S.%f')
            
            except NoResultFound:
                logger.error(NO_DATABASE_ERROR)

                raise InvalidUsage(NO_DATABASE_ERROR, 500)
        
            except MultipleResultsFound:
                logger.error(MULTIPLE_DATABASE_ERROR)
                
                raise InvalidUsage(MULTIPLE_DATABASE_ERROR, 500)
        
        db.session.commit()


class TtlDuration(Resource):
    def get(self):
        try:
            result = Database.query.with_entities(Database.ttl_duration).one()
            
            return jsonify(result.ttl_duration)
        
        except NoResultFound:
            logger.error(NO_DATABASE_ERROR)

            raise InvalidUsage(NO_DATABASE_ERROR, 500)
        
        except MultipleResultsFound:
            logger.error(MULTIPLE_DATABASE_ERROR)
                
            raise InvalidUsage(MULTIPLE_DATABASE_ERROR, 500)
        

class TtlLastExecution(Resource):
    def get(self):
        try:
            result = Database.query.with_entities(Database.ttl_last_execution).one()
            
            return jsonify(result.ttl_last_execution)
        
        except NoResultFound:
            logger.error(NO_DATABASE_ERROR)

            raise InvalidUsage(NO_DATABASE_ERROR, 500)
        
        except MultipleResultsFound:
            logger.error(MULTIPLE_DATABASE_ERROR)
                
            raise InvalidUsage(MULTIPLE_DATABASE_ERROR, 500)


class AttributeRowDeleted(Resource):
    def get(self, att_name):
        try:
            result = Attribute.query.with_entities(Attribute.ttl_rows_deleted).filter(Attribute.name == att_name).one()
            
            if result.ttl_rows_deleted is None:
                message = "Attribute {} was not processed last time ttl script was executed".format(att_name)
                logger.error(message)
                
                raise InvalidUsage(message, 404)
            
            return jsonify(result.ttl_rows_deleted)
        
        except NoResultFound:
            message = "Attribute: {} is not configured for ttl".format(att_name)
            logger.error(message)
            
            raise InvalidUsage(message)

