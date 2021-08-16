-- -----------------------------------------------------------------------------
-- This file is part of the hdbpp-timescale-project
--
-- Copyright (C) : 2014-2019
--   European Synchrotron Radiation Facility
--   BP 220, Grenoble 38043, FRANCE
--
-- libhdb++timescale is free software: you can redistribute it and/or modify
-- it under the terms of the Lesser GNU General Public License as published by
-- the Free Software Foundation, either version 3 of the License, or
-- (at your option) any later version.
--
-- libhdb++timescale is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the Lesser
-- GNU General Public License for more details.
--
-- You should have received a copy of the Lesser GNU General Public License
-- along with libhdb++timescale.  If not, see <http://www.gnu.org/licenses/>.
-- -----------------------------------------------------------------------------

\c hdb

-- Some useful users for a basic system
CREATE ROLE hdb_cfg_man WITH LOGIN PASSWORD 'hdbpp';
GRANT readwrite TO hdb_cfg_man;

CREATE ROLE hdb_event_sub WITH LOGIN PASSWORD 'hdbpp';
GRANT readwrite TO hdb_event_sub;

CREATE ROLE hdb_data_reporter WITH LOGIN PASSWORD 'hdbpp';
GRANT readonly TO hdb_data_reporter;
