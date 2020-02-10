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

import os

# simple configurations for the server


class Config:
    SECRET_KEY = os.getenv("SECRET_KEY", "my_precious_secret_key")
    SQLALCHEMY_TRACK_MODIFICATIONS = False


class DevelopmentConfig(Config):
    DEBUG = True
    SQLALCHEMY_DATABASE_URI ="sqlite:////tmp/reporting.db"


class TestingConfig(Config):
    DEBUG = True
    TESTING = True
    PRESERVE_CONTEXT_ON_EXCEPTION = False
    SQLALCHEMY_DATABASE_URI = "sqlite:////tmp/reporting.db"


class ProductionConfig(Config):
    DEBUG = False
    SQLALCHEMY_DATABASE_URI = os.environ.get("DATABASE_URL") or "sqlite:////tmp/reporting.db"


config_by_name = dict(
    dev=DevelopmentConfig,
    test=TestingConfig,
    prod=ProductionConfig
)

key = Config.SECRET_KEY

LOGGER_NAME = "hdbpp_cluster_reporting"
version_major = 0
version_minor = 2
version_patch = 0

# Constants used in some places, make it easier to modify the strings later
CONNECTION_STATE_ERROR = "connection error"
CONNECTION_STATE_UNKNOWN = "unknown"
SERVER_ROLE_UNKNOWN = "unknown"
#Supported types and format, the one not listed there will generate errors on queries.
DB_TYPES = ['DEV_BOOLEAN', 'DEV_SHORT', 'DEV_LONG', 'DEV_FLOAT', 'DEV_DOUBLE', 'DEV_USHORT', 'DEV_ULONG', 'DEV_STRING', 'DEV_STATE', 'DEV_UCHAR', 'DEV_LONG64', 'DEV_ULONG64']
DB_FORMAT = ['SCALAR', 'SPECTRUM']
