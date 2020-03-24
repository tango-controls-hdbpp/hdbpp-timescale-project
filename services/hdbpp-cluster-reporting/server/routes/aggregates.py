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
from server.models import Aggregate
from sqlalchemy.sql import func
from flask_restplus import Resource
from flask import jsonify, abort
from server.errors import InvalidUsage

logger = logging.getLogger(config.LOGGER_NAME)

def get_from_db(att_format, att_type, att_interval, req):
    """
    Generic function that just grabs the data from the database according
    to the format, type and interval.
    Attributes:
    -----------
        att_format: str -- Format of the attribute to query.
        att_type: str -- Type of the attribute to query.
        att_interval: str -- Interval of the aggregate to query.
        req: SQLAlchemy InstrumentedAttributes -- Output field requested.
    """
    if att_type not in config.DB_TYPES or att_format not in config.DB_FORMAT or att_interval not in config.AGG_INTERVAL:
        logger.error("The type: {} and format: {} is not supported for {} interval.".format(att_type, att_format, att_interval))
        raise InvalidUsage("The type: {} and format: {} is not supported for {} interval.".format(att_type, att_format, att_interval))

    attributes_result = Aggregate.query \
            .with_entities(req.label('result')) \
            .filter(Aggregate.att_type == att_type, Aggregate.att_format == att_format, Aggregate.agg_interval == att_interval)

    return attributes_result[0].result


class Aggregates(Resource):
    def get(self):
        aggregates = {}
        aggs_result = Aggregate.query.all()
                    
        for aggregate in aggs_result:
            if aggregate.att_format not in aggregates:
                aggregates[aggregate.att_format] = {}
            
            if aggregate.att_type not in aggregates[aggregate.att_format]:
                aggregates[aggregate.att_format][aggregate.att_type] = []
                
            aggregates[aggregate.att_format][aggregate.att_type].append(aggregate.agg_interval)
        
        return jsonify(aggregates)


class AggregatesRowCount(Resource):
    def get(self, att_format, att_type, agg_interval):
        return jsonify(get_from_db(att_format, att_type, agg_interval, Aggregate.agg_row_count))


class AggregatesSize(Resource):
    def get(self, att_format, att_type, agg_interval):
        result = {'unit':"bytes"}
        result['size'] = get_from_db(att_format, att_type, agg_interval, Aggregate.agg_size)
        return jsonify(result)

