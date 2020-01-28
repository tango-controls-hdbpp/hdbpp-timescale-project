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

#class Attributes(Resource):
#    def get(self):
#        return jsonify(hosts)

#class ScalarAttributes(Resource):
#    def get(self):
#        return jsonify(hosts)

#class SpectrumAttributes(Resource):
#    def get(self):
#        return jsonify(1)