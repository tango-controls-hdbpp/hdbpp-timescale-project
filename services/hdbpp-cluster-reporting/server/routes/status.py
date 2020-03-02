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

import server.models as models
import server.config as config

from flask_restplus import Resource

# Endpoints that report composite status and summary info

class ServerHealth(Resource):
    def get(self):
        servers_result = models.Servers.query.all()

        # this is a simple staus check, based on the state of the
        # servers. We may expand this in future to be more complex,
        # but its not easy to compress the cluster status down into
        # a single result
        for server in servers_result:
            if server.state == config.CONNECTION_STATE_ERROR:
                return {"state": "Error"
                        , "message": "An error occured while connecting to the database {}".format(server.hostname)}

            if server.state == config.CONNECTION_STATE_UNKNOWN:
                return {"state": "Warning"
                        , "message": "Connection state to {} is unknown.".format(server.hostname)}

            if server.role == config.SERVER_ROLE_UNKNOWN:
                return {"state": "Warning"
                        , "message": "Cannot retrieve the role of {}.".format(server.hostname)}

        return {"state": "Ok"}
