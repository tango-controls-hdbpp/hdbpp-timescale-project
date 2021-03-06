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
from server.models import Datatable
from sqlalchemy.sql import func
from flask_restplus import Resource
from flask import jsonify, abort
from server.errors import InvalidUsage

logger = logging.getLogger(config.LOGGER_NAME)

def get_bytes(size):
    """
    Helper function to convert a size given in standard units (1G for example)
    to bytes.
    
    Arguments:
        size: str
        string representation of the size

    Returns:
        int -- the size in bytes
    """
   
    standard_size = ['K', 'M', 'G', 'T']
    init = size
    num = ""
    
    while size and size[0:1].isdigit() or size[0:1] == '.':
        num += size[0]
        size = size[1:]
    
    num = float(num)
    first_letter = size.strip()[:1]
    pow_idx = -1;
    
    for index, prefix in enumerate(standard_size):
        if first_letter.upper() == prefix:
            pow_idx = index
            break
    
    if pow_idx < 0:
        logger.error("Could not convert {} to bytes.".format(init))
        return num

    return int(num * 1024 ** (pow_idx+1))


def get_from_db(att_format, att_type, req):
    """
    Generic function that just grabs the data from the database according
    to the format and type.
    Attributes:
    -----------
        att_format: str -- Format of the attribute to query.
        att_type: str -- Type of the attribute to query.
        req: SQLAlchemy InstrumentedAttributes -- Output field requested.
    """
    if att_type not in config.DB_TYPES or att_format not in config.DB_FORMAT:
        logger.error("The type: {} and format: {} is not supported.".format(att_type, att_format))
        raise InvalidUsage("The type: {} and format: {} is not supported.".format(att_type, att_format))

    attributes_result = Datatable.query \
            .with_entities(req.label('result')) \
            .filter(Datatable.att_type == att_type, Datatable.att_format == att_format)

    return attributes_result[0].result

class Health(Resource):

    def __init__(self, *args, **kwargs):
        self.levels = {}
        self.levels['error_bytes']=get_bytes(kwargs['error'])
        self.levels['warning_bytes']=get_bytes(kwargs['warning'])
        self.levels['error_readable']=kwargs['error']
        self.levels['warning_readable']=kwargs['warning']
        
    def get(self):
        atts_result = Datatable.query.all()
            
        ## status check to ensure that the last chunk is not too big
        for attribute in atts_result:
            if attribute.att_current_chunk_size > self.levels['error_bytes']:
                return {"state": "Error"
                        , "message": "The last chunk for attributes {} of format {} is bigger than {}." \
                                .format(attribute.att_type, attribute.att_format, self.levels['error_readable'])}
            
            if attribute.att_current_chunk_size > self.levels['warning_bytes']:
                return {"state": "Warning"
                        , "message": "The last chunk for attributes {} of format {} is bigger than {}." \
                                .format(attribute.att_type, attribute.att_format, self.levels['warning_readable'])}

        return {"state": "Ok"
                , "message": "The last chunks sizes are smaller than {}.".format(self.levels['warning_readable'])}
        

class Attributes(Resource):
    def get(self):
        attributes = {}
        atts_result = Datatable.query.all()
        
        for attribute in atts_result:
            if attribute.att_format not in attributes:
                attributes[attribute.att_format] = []
            
            attributes[attribute.att_format].append(attribute.att_type)

        return jsonify(attributes)


class AttributesCount(Resource):
    def get(self):
        attributes_result = Datatable.query.with_entities(func.sum(Datatable.att_count).label('c'))
        return jsonify(attributes_result[0].c)


class AttributesTypeOrFormatCount(Resource):
    def get(self, att_info):
        if att_info not in config.DB_TYPES and att_info not in config.DB_FORMAT:
            logger.error("The type or format: {} is not supported.".format(att_info))
            raise InvalidUsage("The type or format: {} is not supported.".format(att_info))
        
        attributes_result = Datatable.query.with_entities(Datatable.att_type) \
                .filter(Datatable.att_type == att_info)
        
        #Check if the information passed is a type, if not it should be a format.
        if attributes_result.count() == 0:
            attributes_result = Datatable.query.with_entities(func.sum(Datatable.att_count).label('c')) \
                    .group_by(Datatable.att_format).filter(Datatable.att_format == att_info)
        else:
            attributes_result = Datatable.query.with_entities(func.sum(Datatable.att_count).label('c')) \
                    .group_by(Datatable.att_type).filter(Datatable.att_type == att_info)
        
        if attributes_result.count() == 0:
            return 0
        
        return jsonify(attributes_result[0].c)


class AttributesFormat(Resource):
    def get(self):
        return jsonify(config.DB_FORMAT)


class AttributesType(Resource):
    def get(self):
        return jsonify(config.DB_TYPES)


class AttributesFormatCount(Resource):
    def get(self, att_format):
        attributes_result = Datatable.query \
                .with_entities(func.sum(Datatable.att_count).label('c')) \
                .group_by(Datatable.att_format) \
                .filter(Datatable.att_format == att_format)

        return jsonify(attributes_result[0].c)


class AttributesFormatTypeCount(Resource):
    def get(self, att_format, att_type):
        return jsonify(get_from_db(att_format, att_type, Datatable.att_count))


class AttributesIntervalUnit(Resource):
    def get(self):
        return jsonify("us")


class AttributesSizeUnit(Resource):
    def get(self):
        return jsonify("bytes")


class AttributesInterval(Resource):
    def get(self, att_format, att_type):
        result = {'unit': "us"}
        result['interval'] = get_from_db(att_format, att_type, Datatable.att_interval)
        return jsonify(result)


class AttributesRowCount(Resource):
    def get(self, att_format, att_type):
        return jsonify(get_from_db(att_format, att_type, Datatable.att_row_count))


class AttributesSize(Resource):
    def get(self, att_format, att_type):
        result = {'unit': "bytes"}
        result['size'] = get_from_db(att_format, att_type, Datatable.att_size)
        return jsonify(result)


class AttributesCurrentSize(Resource):
    def get(self, att_format, att_type):
        result = {'unit': "bytes"}
        result['size'] = get_from_db(att_format, att_type, Datatable.att_current_chunk_size)
        return jsonify(result)

