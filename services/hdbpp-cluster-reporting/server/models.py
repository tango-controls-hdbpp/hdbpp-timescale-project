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
from server import config

def return_not_none(value, default):
    """
    Helper function to return the value or a default
    one if it's None.

    """
    if value is not None:
        return value
    else:
        return default


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
    lag : int
        for replica only, lag from master
    api_url : str
        url of the pattroni rest endpoint
    version : str
        patroni version
    """
    __tablename__ = 'Servers'
    hostname = db.Column(db.String(), primary_key=True)
    state = db.Column(db.String(), nullable=False)
    role = db.Column(db.String(), nullable=False)
    lag = db.Column(db.Integer, nullable=False)
    api_url = db.Column(db.String(), nullable=False)
    version = db.Column(db.String(), nullable=False)

    def __init__(self, hostname, state=None, role=None, lag=None, api_url=None, version=None):
        self.hostname = hostname
        
        self.state = return_not_none(state, config.CONNECTION_STATE_UNKNOWN)
        self.role = return_not_none(role, config.SERVER_ROLE_UNKNOWN)
        self.lag = return_not_none(lag, 0)
        self.api_url = return_not_none(api_url, "")
        self.version = return_not_none(version, "0.0.0")

    def __repr__(self):
        return "<Server %r" % self.hostname

class Datatable(db.Model):
    """
    Represents information about a datatable of the database

    Attributes
    ----------
    att_type : str
        type of the attributes from this table
    att_format : str
        format of the attributes (Scalar or Spectrum)
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
    __tablename__ = 'Datatable'
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
        return "<Data table %r.%r>" % self.att_format, self.att_type

class Aggregate(db.Model):
    """
    Represents information about an aggregate view in the database

    Attributes
    ----------
    att_type : str
        type of the attributes from this table
    att_format : str
        format of the attributes (Scalar or Spectrum)
    agg_interval : str
        interval this aggregate is running on
    agg_row_count : int
        An estimate of the number of lines for this format and type and interval
    agg_size : int
        Total size of the table, in bytes for this format and type and interval
    """

    __tablename__ = 'Aggregate'
    att_type = db.Column(db.String(), nullable=False, primary_key=True)
    att_format = db.Column(db.String(), nullable=False, primary_key=True)
    agg_interval = db.Column(db.String(), nullable=False, primary_key=True)
    agg_row_count = db.Column(db.Integer, nullable=False)
    agg_size = db.Column(db.Integer, nullable=False)

    def __init__(self, att_format, att_type, agg_interval):
        self.att_type = att_type
        self.att_format = att_format
        self.agg_interval = agg_interval
        self.agg_row_count = 0
        self.agg_size = 0

    def __repr__(self):
        return "<Aggregate view %r.%r: %r>" % self.att_format, self.att_type, self.agg_interval

class Database(db.Model):
    """
    Represents general information about the database
    
    Attributes
    ----------
    name : str
       Name of the database.
    size : int
       size of the database, in bytes.

    """
    
    __tablename__ = 'Database'
    name = db.Column(db.String(), nullable=False, primary_key=True)
    size = db.Column(db.Integer(), nullable=False)

    def __init__(self, name):
        self.name = name
        self.size = 0

class Attribute(db.Model):
    """
    Represents information about an attribute
    
    Attributes
    ----------
    name : str
       Name of the attribute.
    ttl_rows_deleted : int
       Number of rows deleted on the last ttl session.
    """
    
    __tablename__ = 'Attribute'
    name = db.Column(db.String(), nullable=False, primary_key=True)
    ttl_rows_deleted = db.Column(db.Integer(), nullable=True)

    def __init__(self, name, ttl):
        self.name = name
        self.ttl_rows_deleted = ttl
