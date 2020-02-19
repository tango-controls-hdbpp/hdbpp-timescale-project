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
from server import db as db
from server.models import Attribute
from flask_restplus import Resource
from flask import jsonify, request
from server.errors import InvalidUsage
from sqlalchemy.orm.exc import NoResultFound
from sqlalchemy.orm.exc import MultipleResultsFound

logger = logging.getLogger(config.LOGGER_NAME)

class Attributes(Resource):
    def get(self):
        attributes = []
        results = Attribute.query.with_entities(Attribute.name)

        for res in results:
            attributes.append(res.name)
        
        return jsonify(attributes)

    def post(self):
        json = request.get_json()

        attributes = db.session.query(Attribute).all()
        
        for attribute in attributes:
            if attribute.name in json:
                if "ttl_rows_deleted" in json[attribute.name]:
                    attribute.ttl_rows_deleted = json[attribute.name]["ttl_rows_deleted"]
                    json.pop(attribute.name, None)
            
            else:
                attribute.ttl_rows_deleted = None
        
        for attribute, att_info in json.items():
            if "ttl_rows_deleted" in att_info:
                db.session.add(Attribute(attribute, att_info["ttl_rows_deleted"]))
        
        db.session.commit()


class AttributeRowDeleted(Resource):
    def get(self, att_name):
        try:
            result = Attribute.query.with_entities(Attribute.ttl_rows_deleted).filter(Attribute.name == att_name).one()
            
            if result.ttl_rows_deleted is None:
                logger.error(
                        "Attribute {} was not processed last time ttl script was executed".format(att_name))
                raise InvalidUsage("Attribute {} was not processed last time ttl script was executed".format(att_name), 404)
            
            return jsonify(result.ttl_rows_deleted)
        
        except NoResultFound:
            logger.error("Attribute: {} is not configured for ttl".format(att_name))
            raise InvalidUsage("Attribute: {} is not configured for ttl".format(att_name))

