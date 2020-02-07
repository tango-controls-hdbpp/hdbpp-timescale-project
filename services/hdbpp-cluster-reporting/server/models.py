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

class Attributes(db.Model):
    """
    Represents information about the attributes in the database

    Attributes
    ----------
    att_type : str
        type of the attribute
    att_format : str
        format of the attribute (Scalar or Spectrum)
    att_count : int
        Number of attributes with this format and type
    att_row_count : int
        An estimate of the number of lines for this format and type
    att_size : int
        Total size of the table, in bytes for this format and type
    att_current_chunk_size : int
        Total size of the current chunk, in bytes for this format and type
    att_interval : int
        Interval for the chunks, in microseconds, for this format and type
    """
    __tablename__ = 'Attributes'
    att_type = db.Column(db.String(), nullable=False, primary_key=True)
    att_format = db.Column(db.String(), nullable=False, primary_key=True)
    att_count = db.Column(db.Integer, nullable=False)
    att_row_count = db.Column(db.Integer, nullable=False)
    att_size = db.Column(db.Integer, nullable=False)
    att_current_chunk_size = db.Column(db.Integer, nullable=False)
    att_interval = db.Column(db.Integer, nullable=False)

    def __init__(self, att_format, att_type):
        self.att_type = att_type
        self.att_format = att_format
        self.att_count = 0
        self.att_row_count = 0
        self.att_size = 0
        self.att_current_chunk_size = 0
        self.att_interval = 0

    def __repr__(self):
        return "<Attributes %r.%r>" % self.att_format, self.att_type

class Database(db.Model):
    """
    Represents general information about the database
    Attributes
    ----------
    size : int
       size of the database, in bytes.

    """
    __tablename__ = 'Database'
    name = db.Column(db.String(), nullable=False, primary_key=True)
    size = db.Column(db.Integer(), nullable=False)

    def __init__(self, name):
        self.name = name
        self.size = 0
