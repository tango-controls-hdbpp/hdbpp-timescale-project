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

from server import db


class Servers(db.Model):
    """
    Represents the state and summary information about a server in
    the cluster

    Attributes
    ----------
    hostname : str
        server network hostname
    state : str
        server status
    role : str
        server role, i.e. master or replica
    """
    __tablename__ = 'Servers'
    hostname = db.Column(db.String(), primary_key=True)
    state = db.Column(db.String(), nullable=False)
    role = db.Column(db.String(), nullable=False)

    def __init__(self, hostname, state, role):
        self.hostname = hostname
        self.state = state
        self.role = role

    def __repr__(self):
        return "<Server %r" % self.hostname
