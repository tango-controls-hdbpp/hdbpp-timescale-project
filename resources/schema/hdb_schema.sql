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

-- Create the hdb database and use it
CREATE DATABASE hdb;
\c hdb

-- Add the timescaledb extension (Important)
CREATE EXTENSION IF NOT EXISTS timescaledb CASCADE;

-------------------------------------------------------------------------------
DO $$ BEGIN
    CREATE DOMAIN uchar AS numeric(3) -- ALT smallint
        CHECK(VALUE >= 0 AND VALUE <= 255);
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
    CREATE DOMAIN ushort AS numeric(5)  -- ALT integer
        CHECK(VALUE >= 0 AND VALUE <= 65535);
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
    CREATE DOMAIN ulong AS numeric(10) -- ALT bigint
        CHECK(VALUE >= 0 AND VALUE <= 4294967295);
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
    CREATE DOMAIN ulong64 AS numeric(20)
        CHECK(VALUE >= 0 AND VALUE <= 18446744073709551615);
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;
-------------------------------------------------------------------------------

-- Mappings for ths Tango Data Type (used in att_conf)
CREATE TABLE IF NOT EXISTS att_conf_type (
    att_conf_type_id serial NOT NULL,
    type text NOT NULL UNIQUE,
    type_num smallint NOT NULL UNIQUE,
    PRIMARY KEY (att_conf_type_id)
);

COMMENT ON TABLE att_conf_type is 'Attribute data type';

INSERT INTO att_conf_type (type, type_num) VALUES
('DEV_BOOLEAN', 1),('DEV_SHORT', 2),('DEV_LONG', 3),('DEV_FLOAT', 4),
('DEV_DOUBLE', 5),('DEV_USHORT', 6),('DEV_ULONG', 7),('DEV_STRING', 8),
('DEV_STATE', 19),('DEV_UCHAR',22),('DEV_LONG64', 23),('DEV_ULONG64', 24),
('DEV_ENCODED', 28),('DEV_ENUM', 30);

-- Mappings for ths Tango Data Format Type (used in att_conf)
CREATE TABLE IF NOT EXISTS att_conf_format (
    att_conf_format_id serial NOT NULL,
    format text NOT NULL UNIQUE,
    format_num smallint NOT NULL UNIQUE,
    PRIMARY KEY (att_conf_format_id)
);

COMMENT ON TABLE att_conf_format is 'Attribute format type';

INSERT INTO att_conf_format (format, format_num) VALUES
('SCALAR', 0),('SPECTRUM', 1),('IMAGE', 2);

-- Mappings for the Tango Data Write Type (used in att_conf)
CREATE TABLE IF NOT EXISTS att_conf_write (
    att_conf_write_id serial NOT NULL,
    write text NOT NULL UNIQUE,
    write_num smallint NOT NULL UNIQUE,
    PRIMARY KEY (att_conf_write_id)
);

COMMENT ON TABLE att_conf_write is 'Attribute write type';

INSERT INTO att_conf_write (write, write_num) VALUES
('READ', 0),('READ_WITH_WRITE', 1),('WRITE', 2),('READ_WRITE', 3);

-- The att_conf table contains the primary key for all data tables, the
-- att_conf_id. Expanded on the normal hdb++ tables since we add information
-- about the type.
CREATE TABLE IF NOT EXISTS att_conf (
    att_conf_id serial NOT NULL,
    att_name text NOT NULL,
    att_conf_type_id smallint NOT NULL,
    att_conf_format_id smallint NOT NULL,
    att_conf_write_id smallint NOT NULL,
    table_name text NOT NULL,
    cs_name text NOT NULL DEFAULT '',
    domain text NOT NULL DEFAULT '',
    family text NOT NULL DEFAULT '',
    member text NOT NULL DEFAULT '',
    name text NOT NULL DEFAULT '',
    ttl int,
    hide boolean DEFAULT false,
    PRIMARY KEY (att_conf_id),
    FOREIGN KEY (att_conf_type_id) REFERENCES att_conf_type (att_conf_type_id),
    FOREIGN KEY (att_conf_format_id) REFERENCES att_conf_format (att_conf_format_id),
    FOREIGN KEY (att_conf_write_id) REFERENCES att_conf_write (att_conf_write_id),
    UNIQUE (att_name)
);

COMMENT ON TABLE att_conf is 'Attribute Configuration Table';

-------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS att_history_event (
    att_history_event_id serial NOT NULL,
    event text NOT NULL,
    PRIMARY KEY (att_history_event_id)
);

COMMENT ON TABLE att_history_event IS 'Attribute history events description';
CREATE INDEX IF NOT EXISTS att_history_att_history_event_id_idx ON att_history_event (att_history_event_id);

CREATE TABLE IF NOT EXISTS att_history (
    att_conf_id integer NOT NULL,
    att_history_event_id integer NOT NULL,
    event_time timestamp WITH TIME ZONE,
    details json,
    PRIMARY KEY (att_conf_id, event_time),
    FOREIGN KEY (att_conf_id) REFERENCES att_conf (att_conf_id),
    FOREIGN KEY (att_history_event_id) REFERENCES att_history_event (att_history_event_id)
);

COMMENT ON TABLE att_history is 'Attribute Configuration Events History Table';

-------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS att_parameter (
    att_conf_id integer NOT NULL,
    recv_time timestamp WITH TIME ZONE NOT NULL,
    label text NOT NULL DEFAULT '',
    unit text NOT NULL DEFAULT '',
    standard_unit text NOT NULL DEFAULT '',
    display_unit text NOT NULL DEFAULT '',
    format text NOT NULL DEFAULT '',
    archive_rel_change text NOT NULL DEFAULT '',
    archive_abs_change text NOT NULL DEFAULT '',
    archive_period text NOT NULL DEFAULT '',
    description text NOT NULL DEFAULT '',
    details json,
    FOREIGN KEY (att_conf_id) REFERENCES att_conf (att_conf_id)
);

COMMENT ON TABLE att_parameter IS 'Attribute configuration parameters';
CREATE INDEX IF NOT EXISTS att_parameter_recv_time_idx ON att_parameter (recv_time);
CREATE INDEX IF NOT EXISTS att_parameter_att_conf_id_idx ON  att_parameter (att_conf_id);
SELECT create_hypertable('att_parameter', 'recv_time', chunk_time_interval => interval '28 day', create_default_indexes => FALSE);

-------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS att_error_desc (
    att_error_desc_id serial NOT NULL,
    error_desc text NOT NULL,
    PRIMARY KEY (att_error_desc_id),
    UNIQUE (error_desc)
);

COMMENT ON TABLE att_error_desc IS 'Error Description Table';

-------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS att_scalar_devboolean (
    att_conf_id integer NOT NULL,
    data_time timestamp WITH TIME ZONE NOT NULL,
    value_r boolean,
    value_w boolean,
    quality smallint,
    att_error_desc_id integer,
    details json,
    PRIMARY KEY (att_conf_id, data_time),
    FOREIGN KEY (att_conf_id) REFERENCES att_conf (att_conf_id),
    FOREIGN KEY (att_error_desc_id) REFERENCES att_error_desc (att_error_desc_id)
);

COMMENT ON TABLE att_scalar_devboolean IS 'Scalar Boolean Values Table';
CREATE INDEX IF NOT EXISTS att_scalar_devboolean_att_conf_id_idx ON att_scalar_devboolean (att_conf_id);
CREATE INDEX IF NOT EXISTS att_scalar_devboolean_att_conf_id_data_time_idx ON att_scalar_devboolean (att_conf_id,data_time DESC);
SELECT create_hypertable('att_scalar_devboolean', 'data_time', chunk_time_interval => interval '28 day', create_default_indexes => FALSE);

CREATE TABLE IF NOT EXISTS att_array_devboolean (
    att_conf_id integer NOT NULL,
    data_time timestamp WITH TIME ZONE NOT NULL,
    value_r boolean[],
    value_w boolean[],
    quality smallint,
    att_error_desc_id integer,
    details json,
    PRIMARY KEY (att_conf_id, data_time),
    FOREIGN KEY (att_conf_id) REFERENCES att_conf (att_conf_id),
    FOREIGN KEY (att_error_desc_id) REFERENCES att_error_desc (att_error_desc_id)
);

COMMENT ON TABLE att_array_devboolean IS 'Array Boolean Values Table';
CREATE INDEX IF NOT EXISTS att_array_devboolean_att_conf_id_idx ON att_array_devboolean (att_conf_id);
CREATE INDEX IF NOT EXISTS att_array_devboolean_att_conf_id_data_time_idx ON att_array_devboolean (att_conf_id,data_time DESC);
SELECT create_hypertable('att_array_devboolean', 'data_time', chunk_time_interval => interval '28 day', create_default_indexes => FALSE);

CREATE TABLE IF NOT EXISTS att_scalar_devuchar (
    att_conf_id integer NOT NULL,
    data_time timestamp WITH TIME ZONE NOT NULL,
    value_r uchar,
    value_w uchar,
    quality smallint,
    att_error_desc_id integer,
    details json,
    PRIMARY KEY (att_conf_id, data_time),
    FOREIGN KEY (att_conf_id) REFERENCES att_conf (att_conf_id),
    FOREIGN KEY (att_error_desc_id) REFERENCES att_error_desc (att_error_desc_id)
);

COMMENT ON TABLE att_scalar_devuchar IS 'Scalar UChar Values Table';
CREATE INDEX IF NOT EXISTS att_scalar_devuchar_att_conf_id_idx ON att_scalar_devuchar (att_conf_id);
CREATE INDEX IF NOT EXISTS att_scalar_devuchar_att_conf_id_data_time_idx ON att_scalar_devuchar (att_conf_id,data_time DESC);
SELECT create_hypertable('att_scalar_devuchar', 'data_time', chunk_time_interval => interval '28 day', create_default_indexes => FALSE);

CREATE TABLE IF NOT EXISTS att_array_devuchar (
    att_conf_id integer NOT NULL,
    data_time timestamp WITH TIME ZONE NOT NULL,
    value_r uchar[],
    value_w uchar[],
    quality smallint,
    details json,
    att_error_desc_id integer,
    PRIMARY KEY (att_conf_id, data_time),
    FOREIGN KEY (att_conf_id) REFERENCES att_conf (att_conf_id),
    FOREIGN KEY (att_error_desc_id) REFERENCES att_error_desc (att_error_desc_id)
);

COMMENT ON TABLE att_array_devuchar IS 'Array UChar Values Table';
CREATE INDEX IF NOT EXISTS att_array_devuchar_att_conf_id_idx ON att_array_devuchar (att_conf_id);
CREATE INDEX IF NOT EXISTS att_array_devuchar_att_conf_id_data_time_idx ON att_array_devuchar (att_conf_id,data_time DESC);
SELECT create_hypertable('att_array_devuchar', 'data_time', chunk_time_interval => interval '28 day', create_default_indexes => FALSE);

CREATE TABLE IF NOT EXISTS att_scalar_devshort (
    att_conf_id integer NOT NULL,
    data_time timestamp WITH TIME ZONE NOT NULL,
    value_r smallint,
    value_w smallint,
    quality smallint,
    details json,
    att_error_desc_id integer,
    PRIMARY KEY (att_conf_id, data_time),
    FOREIGN KEY (att_conf_id) REFERENCES att_conf (att_conf_id),
    FOREIGN KEY (att_error_desc_id) REFERENCES att_error_desc (att_error_desc_id)
);

COMMENT ON TABLE att_scalar_devshort IS 'Scalar Short Values Table';
CREATE INDEX IF NOT EXISTS att_scalar_devshort_att_conf_id_idx ON att_scalar_devshort (att_conf_id);
CREATE INDEX IF NOT EXISTS att_scalar_devshort_att_conf_id_data_time_idx ON att_scalar_devshort (att_conf_id,data_time DESC);
SELECT create_hypertable('att_scalar_devshort', 'data_time', chunk_time_interval => interval '28 day', create_default_indexes => FALSE);

CREATE TABLE IF NOT EXISTS att_array_devshort (
    att_conf_id integer NOT NULL,
    data_time timestamp WITH TIME ZONE NOT NULL,
    value_r smallint[],
    value_w smallint[],
    quality smallint,
    att_error_desc_id integer,
    details json,
    PRIMARY KEY (att_conf_id, data_time),
    FOREIGN KEY (att_conf_id) REFERENCES att_conf (att_conf_id),
    FOREIGN KEY (att_error_desc_id) REFERENCES att_error_desc (att_error_desc_id)
);

COMMENT ON TABLE att_array_devshort IS 'Array Short Values Table';
CREATE INDEX IF NOT EXISTS att_array_devshort_att_conf_id_idx ON att_array_devshort (att_conf_id);
CREATE INDEX IF NOT EXISTS att_array_devshort_att_conf_id_data_time_idx ON att_array_devshort (att_conf_id,data_time DESC);
SELECT create_hypertable('att_array_devshort', 'data_time', chunk_time_interval => interval '28 day', create_default_indexes => FALSE);

CREATE TABLE IF NOT EXISTS att_scalar_devushort (
    att_conf_id integer NOT NULL,
    data_time timestamp WITH TIME ZONE NOT NULL,
    value_r ushort,
    value_w ushort,
    quality smallint,
    att_error_desc_id integer,
    details json,
    PRIMARY KEY (att_conf_id, data_time),
    FOREIGN KEY (att_conf_id) REFERENCES att_conf (att_conf_id),
    FOREIGN KEY (att_error_desc_id) REFERENCES att_error_desc (att_error_desc_id)
);

COMMENT ON TABLE att_scalar_devushort IS 'Scalar UShort Values Table';
CREATE INDEX IF NOT EXISTS att_scalar_devushort_att_conf_id_idx ON att_scalar_devushort (att_conf_id);
CREATE INDEX IF NOT EXISTS att_scalar_devushort_att_conf_id_data_time_idx ON att_scalar_devushort (att_conf_id,data_time DESC);
SELECT create_hypertable('att_scalar_devushort', 'data_time', chunk_time_interval => interval '28 day', create_default_indexes => FALSE);

CREATE TABLE IF NOT EXISTS att_array_devushort (
    att_conf_id integer NOT NULL,
    data_time timestamp WITH TIME ZONE NOT NULL,
    value_r ushort[],
    value_w ushort[],
    quality smallint,
    att_error_desc_id integer,
    details json,
    PRIMARY KEY (att_conf_id, data_time),
    FOREIGN KEY (att_conf_id) REFERENCES att_conf (att_conf_id),
    FOREIGN KEY (att_error_desc_id) REFERENCES att_error_desc (att_error_desc_id)
);

COMMENT ON TABLE att_array_devushort IS 'Array UShort Values Table';
CREATE INDEX IF NOT EXISTS att_array_devushort_att_conf_id_idx ON att_array_devushort (att_conf_id);
CREATE INDEX IF NOT EXISTS att_array_devushort_att_conf_id_data_time_idx ON att_array_devushort (att_conf_id,data_time DESC);
SELECT create_hypertable('att_array_devushort', 'data_time', chunk_time_interval => interval '28 day', create_default_indexes => FALSE);

CREATE TABLE IF NOT EXISTS att_scalar_devlong (
    att_conf_id integer NOT NULL,
    data_time timestamp WITH TIME ZONE NOT NULL,
    value_r integer,
    value_w integer,
    quality smallint,
    att_error_desc_id integer,
    details json,
    PRIMARY KEY (att_conf_id, data_time),
    FOREIGN KEY (att_conf_id) REFERENCES att_conf (att_conf_id),
    FOREIGN KEY (att_error_desc_id) REFERENCES att_error_desc (att_error_desc_id)
);

COMMENT ON TABLE att_scalar_devlong IS 'Scalar Long Values Table';
CREATE INDEX IF NOT EXISTS att_scalar_devlong_att_conf_id_idx ON att_scalar_devlong (att_conf_id);
CREATE INDEX IF NOT EXISTS att_scalar_devlong_att_conf_id_data_time_idx ON att_scalar_devlong (att_conf_id,data_time DESC);
SELECT create_hypertable('att_scalar_devlong', 'data_time', chunk_time_interval => interval '28 day', create_default_indexes => FALSE);

CREATE TABLE IF NOT EXISTS att_array_devlong (
    att_conf_id integer NOT NULL,
    data_time timestamp WITH TIME ZONE NOT NULL,
    value_r integer[],
    value_w integer[],
    quality smallint,
    att_error_desc_id integer,
    details json,
    PRIMARY KEY (att_conf_id, data_time),
    FOREIGN KEY (att_conf_id) REFERENCES att_conf (att_conf_id),
    FOREIGN KEY (att_error_desc_id) REFERENCES att_error_desc (att_error_desc_id)
);

COMMENT ON TABLE att_array_devlong IS 'Array Long Values Table';
CREATE INDEX IF NOT EXISTS att_array_devlong_att_conf_id_idx ON att_array_devlong (att_conf_id);
CREATE INDEX IF NOT EXISTS att_array_devlong_att_conf_id_data_time_idx ON att_array_devlong (att_conf_id,data_time DESC);
SELECT create_hypertable('att_array_devlong', 'data_time', chunk_time_interval => interval '28 day', create_default_indexes => FALSE);

CREATE TABLE IF NOT EXISTS att_scalar_devulong (
    att_conf_id integer NOT NULL,
    data_time timestamp WITH TIME ZONE NOT NULL,
    value_r ulong,
    value_w ulong,
    quality smallint,
    att_error_desc_id integer,
    details json,
    PRIMARY KEY (att_conf_id, data_time),
    FOREIGN KEY (att_conf_id) REFERENCES att_conf (att_conf_id),
    FOREIGN KEY (att_error_desc_id) REFERENCES att_error_desc (att_error_desc_id)
);

COMMENT ON TABLE att_scalar_devulong IS 'Scalar ULong Values Table';
CREATE INDEX IF NOT EXISTS att_scalar_devulong_att_conf_id_idx ON att_scalar_devulong (att_conf_id);
CREATE INDEX IF NOT EXISTS att_scalar_devulong_att_conf_id_data_time_idx ON att_scalar_devulong (att_conf_id,data_time DESC);
SELECT create_hypertable('att_scalar_devulong', 'data_time', chunk_time_interval => interval '28 day', create_default_indexes => FALSE);

CREATE TABLE IF NOT EXISTS att_array_devulong (
    att_conf_id integer NOT NULL,
    data_time timestamp WITH TIME ZONE NOT NULL,
    value_r ulong[],
    value_w ulong[],
    quality smallint,
    att_error_desc_id integer,
    details json,
    PRIMARY KEY (att_conf_id, data_time),
    FOREIGN KEY (att_conf_id) REFERENCES att_conf (att_conf_id),
    FOREIGN KEY (att_error_desc_id) REFERENCES att_error_desc (att_error_desc_id)
);

COMMENT ON TABLE att_array_devulong IS 'Array ULong Values Table';
CREATE INDEX IF NOT EXISTS att_array_devulong_att_conf_id_idx ON att_array_devulong (att_conf_id);
CREATE INDEX IF NOT EXISTS att_array_devulong_att_conf_id_data_time_idx ON att_array_devulong (att_conf_id,data_time DESC);
SELECT create_hypertable('att_array_devulong', 'data_time', chunk_time_interval => interval '28 day', create_default_indexes => FALSE);

CREATE TABLE IF NOT EXISTS att_scalar_devlong64 (
    att_conf_id integer NOT NULL,
    data_time timestamp WITH TIME ZONE NOT NULL,
    value_r bigint,
    value_w bigint,
    quality smallint,
    att_error_desc_id integer,
    details json,
    PRIMARY KEY (att_conf_id, data_time),
    FOREIGN KEY (att_conf_id) REFERENCES att_conf (att_conf_id),
    FOREIGN KEY (att_error_desc_id) REFERENCES att_error_desc (att_error_desc_id)
);

COMMENT ON TABLE att_scalar_devlong64 IS 'Scalar Long64 Values Table';
CREATE INDEX IF NOT EXISTS att_scalar_devlong64_att_conf_id_idx ON att_scalar_devlong64 (att_conf_id);
CREATE INDEX IF NOT EXISTS att_scalar_devlong64_att_conf_id_data_time_idx ON att_scalar_devlong64 (att_conf_id,data_time DESC);
SELECT create_hypertable('att_scalar_devlong64', 'data_time', chunk_time_interval => interval '28 day', create_default_indexes => FALSE);

CREATE TABLE IF NOT EXISTS att_array_devlong64 (
    att_conf_id integer NOT NULL,
    data_time timestamp WITH TIME ZONE NOT NULL,
    value_r bigint[],
    value_w bigint[],
    quality smallint,
    att_error_desc_id integer,
    details json,
    PRIMARY KEY (att_conf_id, data_time),
    FOREIGN KEY (att_conf_id) REFERENCES att_conf (att_conf_id),
    FOREIGN KEY (att_error_desc_id) REFERENCES att_error_desc (att_error_desc_id)
);

COMMENT ON TABLE att_array_devlong64 IS 'Array Long64 Values Table';
CREATE INDEX IF NOT EXISTS att_array_devlong64_att_conf_id_idx ON att_array_devlong64 (att_conf_id);
CREATE INDEX IF NOT EXISTS att_array_devlong64_att_conf_id_data_time_idx ON att_array_devlong64 (att_conf_id,data_time DESC);
SELECT create_hypertable('att_array_devlong64', 'data_time', chunk_time_interval => interval '28 day', create_default_indexes => FALSE);

CREATE TABLE IF NOT EXISTS att_scalar_devulong64 (
    att_conf_id integer NOT NULL,
    data_time timestamp WITH TIME ZONE NOT NULL,
    value_r ulong64,
    value_w ulong64,
    quality smallint,
    att_error_desc_id integer,
    details json,
    PRIMARY KEY (att_conf_id, data_time),
    FOREIGN KEY (att_conf_id) REFERENCES att_conf (att_conf_id),
    FOREIGN KEY (att_error_desc_id) REFERENCES att_error_desc (att_error_desc_id)
);

COMMENT ON TABLE att_scalar_devulong64 IS 'Scalar ULong64 Values Table';
CREATE INDEX IF NOT EXISTS att_scalar_devulong64_att_conf_id_idx ON att_scalar_devulong64 (att_conf_id);
CREATE INDEX IF NOT EXISTS att_scalar_devulong64_att_conf_id_data_time_idx ON att_scalar_devulong64 (att_conf_id,data_time DESC);
SELECT create_hypertable('att_scalar_devulong64', 'data_time', chunk_time_interval => interval '28 day', create_default_indexes => FALSE);

CREATE TABLE IF NOT EXISTS att_array_devulong64 (
    att_conf_id integer NOT NULL,
    data_time timestamp WITH TIME ZONE NOT NULL,
    value_r ulong64[],
    value_w ulong64[],
    quality smallint,
    att_error_desc_id integer,
    details json,
    PRIMARY KEY (att_conf_id, data_time),
    FOREIGN KEY (att_conf_id) REFERENCES att_conf (att_conf_id),
    FOREIGN KEY (att_error_desc_id) REFERENCES att_error_desc (att_error_desc_id)
);

COMMENT ON TABLE att_array_devulong64 IS 'Array ULong64 Values Table';
CREATE INDEX IF NOT EXISTS att_array_devulong64_att_conf_id_idx ON att_array_devulong64 (att_conf_id);
CREATE INDEX IF NOT EXISTS att_array_devulong64_att_conf_id_data_time_idx ON att_array_devulong64 (att_conf_id,data_time DESC);
SELECT create_hypertable('att_array_devulong64', 'data_time', chunk_time_interval => interval '28 day', create_default_indexes => FALSE);

CREATE TABLE IF NOT EXISTS att_scalar_devfloat (
    att_conf_id integer NOT NULL,
    data_time timestamp WITH TIME ZONE NOT NULL,
    value_r real,
    value_w real,
    quality smallint,
    att_error_desc_id integer,
    details json,
    PRIMARY KEY (att_conf_id, data_time),
    FOREIGN KEY (att_conf_id) REFERENCES att_conf (att_conf_id),
    FOREIGN KEY (att_error_desc_id) REFERENCES att_error_desc (att_error_desc_id)
);

COMMENT ON TABLE att_scalar_devfloat IS 'Scalar Float Values Table';
CREATE INDEX IF NOT EXISTS att_scalar_devfloat_att_conf_id_idx ON att_scalar_devfloat (att_conf_id);
CREATE INDEX IF NOT EXISTS att_scalar_devfloat_att_conf_id_data_time_idx ON att_scalar_devfloat (att_conf_id,data_time DESC);
SELECT create_hypertable('att_scalar_devfloat', 'data_time', chunk_time_interval => interval '28 day', create_default_indexes => FALSE);

CREATE TABLE IF NOT EXISTS att_array_devfloat (
    att_conf_id integer NOT NULL,
    data_time timestamp WITH TIME ZONE NOT NULL,
    value_r real[],
    value_w real[],
    quality smallint,
    att_error_desc_id integer,
    details json,
    PRIMARY KEY (att_conf_id, data_time),
    FOREIGN KEY (att_conf_id) REFERENCES att_conf (att_conf_id),
    FOREIGN KEY (att_error_desc_id) REFERENCES att_error_desc (att_error_desc_id)
);

COMMENT ON TABLE att_array_devfloat IS 'Array Float Values Table';
CREATE INDEX IF NOT EXISTS att_array_devfloat_att_conf_id_idx ON att_array_devfloat (att_conf_id);
CREATE INDEX IF NOT EXISTS att_array_devfloat_att_conf_id_data_time_idx ON att_array_devfloat (att_conf_id,data_time DESC);
SELECT create_hypertable('att_array_devfloat', 'data_time', chunk_time_interval => interval '28 day', create_default_indexes => FALSE);

CREATE TABLE IF NOT EXISTS att_scalar_devdouble (
    att_conf_id integer NOT NULL,
    data_time timestamp WITH TIME ZONE NOT NULL,
    value_r double precision,
    value_w double precision,
    quality smallint,
    att_error_desc_id integer,
    details json,
    PRIMARY KEY (att_conf_id, data_time),
    FOREIGN KEY (att_conf_id) REFERENCES att_conf (att_conf_id),
    FOREIGN KEY (att_error_desc_id) REFERENCES att_error_desc (att_error_desc_id)
);

COMMENT ON TABLE att_scalar_devdouble IS 'Scalar Double Values Table';
CREATE INDEX IF NOT EXISTS att_scalar_devdouble_att_conf_id_idx ON att_scalar_devdouble (att_conf_id);
CREATE INDEX IF NOT EXISTS att_scalar_devdouble_att_conf_id_data_time_idx ON att_scalar_devdouble (att_conf_id,data_time DESC);
SELECT create_hypertable('att_scalar_devdouble', 'data_time', chunk_time_interval => interval '14 day', create_default_indexes => FALSE);

CREATE TABLE IF NOT EXISTS att_array_devdouble (
    att_conf_id integer NOT NULL,
    data_time timestamp WITH TIME ZONE NOT NULL,
    value_r double precision[],
    value_w double precision[],
    quality smallint,
    att_error_desc_id integer,
    details json,
    PRIMARY KEY (att_conf_id, data_time),
    FOREIGN KEY (att_conf_id) REFERENCES att_conf (att_conf_id),
    FOREIGN KEY (att_error_desc_id) REFERENCES att_error_desc (att_error_desc_id)
);

COMMENT ON TABLE att_array_devdouble IS 'Array Double Values Table';
CREATE INDEX IF NOT EXISTS att_array_devdouble_att_conf_id_idx ON att_array_devdouble (att_conf_id);
CREATE INDEX IF NOT EXISTS att_array_devdouble_att_conf_id_data_time_idx ON att_array_devdouble (att_conf_id,data_time DESC);
SELECT create_hypertable('att_array_devdouble', 'data_time', chunk_time_interval => interval '28 day', create_default_indexes => FALSE);

CREATE TABLE IF NOT EXISTS att_scalar_devstring (
    att_conf_id integer NOT NULL,
    data_time timestamp WITH TIME ZONE NOT NULL,
    value_r text,
    value_w text,
    quality smallint,
    att_error_desc_id integer,
    details json,
    PRIMARY KEY (att_conf_id, data_time),
    FOREIGN KEY (att_conf_id) REFERENCES att_conf (att_conf_id),
    FOREIGN KEY (att_error_desc_id) REFERENCES att_error_desc (att_error_desc_id)
);

COMMENT ON TABLE att_scalar_devstring IS 'Scalar String Values Table';
CREATE INDEX IF NOT EXISTS att_scalar_devstring_att_conf_id_idx ON att_scalar_devstring (att_conf_id);
CREATE INDEX IF NOT EXISTS att_scalar_devstring_att_conf_id_data_time_idx ON att_scalar_devstring (att_conf_id,data_time DESC);
SELECT create_hypertable('att_scalar_devstring', 'data_time', chunk_time_interval => interval '28 day', create_default_indexes => FALSE);

CREATE TABLE IF NOT EXISTS att_array_devstring (
    att_conf_id integer NOT NULL,
    data_time timestamp WITH TIME ZONE NOT NULL,
    value_r text[],
    value_w text[],
    quality smallint,
    att_error_desc_id integer,
    details json,
    PRIMARY KEY (att_conf_id, data_time),
    FOREIGN KEY (att_conf_id) REFERENCES att_conf (att_conf_id),
    FOREIGN KEY (att_error_desc_id) REFERENCES att_error_desc (att_error_desc_id)
);

COMMENT ON TABLE att_array_devstring IS 'Array String Values Table';
CREATE INDEX IF NOT EXISTS att_array_devstring_att_conf_id_idx ON att_array_devstring (att_conf_id);
CREATE INDEX IF NOT EXISTS att_array_devstring_att_conf_id_data_time_idx ON att_array_devstring (att_conf_id,data_time DESC);
SELECT create_hypertable('att_array_devstring', 'data_time', chunk_time_interval => interval '28 day', create_default_indexes => FALSE);

CREATE TABLE IF NOT EXISTS att_scalar_devstate (
    att_conf_id integer NOT NULL,
    data_time timestamp WITH TIME ZONE NOT NULL,
    value_r integer,
    value_w integer,
    quality smallint,
    att_error_desc_id integer,
    details json,
    PRIMARY KEY (att_conf_id, data_time),
    FOREIGN KEY (att_conf_id) REFERENCES att_conf (att_conf_id),
    FOREIGN KEY (att_error_desc_id) REFERENCES att_error_desc (att_error_desc_id)
);

COMMENT ON TABLE att_scalar_devstate IS 'Scalar State Values Table';
CREATE INDEX IF NOT EXISTS att_scalar_devstate_att_conf_id_idx ON att_scalar_devstate (att_conf_id);
CREATE INDEX IF NOT EXISTS att_scalar_devstate_att_conf_id_data_time_idx ON att_scalar_devstate (att_conf_id,data_time DESC);
SELECT create_hypertable('att_scalar_devstate', 'data_time', chunk_time_interval => interval '28 day', create_default_indexes => FALSE);

CREATE TABLE IF NOT EXISTS att_array_devstate (
    att_conf_id integer NOT NULL,
    data_time timestamp WITH TIME ZONE NOT NULL,
    value_r integer[],
    value_w integer[],
    quality smallint,
    att_error_desc_id integer,
    details json,
    PRIMARY KEY (att_conf_id, data_time),
    FOREIGN KEY (att_conf_id) REFERENCES att_conf (att_conf_id),
    FOREIGN KEY (att_error_desc_id) REFERENCES att_error_desc (att_error_desc_id)
);

COMMENT ON TABLE att_array_devstate IS 'Array State Values Table';
CREATE INDEX IF NOT EXISTS att_array_devstate_att_conf_id_idx ON att_array_devstate (att_conf_id);
CREATE INDEX IF NOT EXISTS att_array_devstate_att_conf_id_data_time_idx ON att_array_devstate (att_conf_id,data_time DESC);
SELECT create_hypertable('att_array_devstate', 'data_time', chunk_time_interval => interval '28 day', create_default_indexes => FALSE);

CREATE TABLE IF NOT EXISTS att_scalar_devencoded (
    att_conf_id integer NOT NULL,
    data_time timestamp WITH TIME ZONE NOT NULL,
    value_r bytea,
    value_w bytea,
    quality smallint,
    att_error_desc_id integer,
    details json,
    PRIMARY KEY (att_conf_id, data_time),
    FOREIGN KEY (att_conf_id) REFERENCES att_conf (att_conf_id),
    FOREIGN KEY (att_error_desc_id) REFERENCES att_error_desc (att_error_desc_id)
);
COMMENT ON TABLE att_scalar_devencoded IS 'Scalar DevEncoded Values Table';
CREATE INDEX IF NOT EXISTS att_scalar_devencoded_att_conf_id_idx ON att_scalar_devencoded (att_conf_id);
CREATE INDEX IF NOT EXISTS att_scalar_devencoded_att_conf_id_data_time_idx ON att_scalar_devencoded (att_conf_id,data_time DESC);
SELECT create_hypertable('att_scalar_devencoded', 'data_time', chunk_time_interval => interval '28 day', create_default_indexes => FALSE);

CREATE TABLE IF NOT EXISTS att_array_devencoded (
    att_conf_id integer NOT NULL,
    data_time timestamp WITH TIME ZONE NOT NULL,
    value_r bytea[],
    value_w bytea[],
    quality smallint,
    att_error_desc_id integer,
    details json,
    PRIMARY KEY (att_conf_id, data_time),
    FOREIGN KEY (att_conf_id) REFERENCES att_conf (att_conf_id),
    FOREIGN KEY (att_error_desc_id) REFERENCES att_error_desc (att_error_desc_id)
);
COMMENT ON TABLE att_array_devencoded IS 'Array DevEncoded Values Table';
CREATE INDEX IF NOT EXISTS att_array_devencoded_att_conf_id_idx ON att_array_devencoded (att_conf_id);
CREATE INDEX IF NOT EXISTS att_array_devencoded_att_conf_id_data_time_idx ON att_array_devencoded (att_conf_id,data_time DESC);
SELECT create_hypertable('att_array_devencoded', 'data_time', chunk_time_interval => interval '28 day', create_default_indexes => FALSE);

-- The Enum tables are unique in that they store a value and text label for 
-- each data point
CREATE TABLE IF NOT EXISTS att_scalar_devenum (
    att_conf_id integer NOT NULL,
    data_time timestamp WITH TIME ZONE NOT NULL,
    value_r_label text,
    value_r smallint,
    value_w_label text,
    value_w smallint,
    quality smallint,
    att_error_desc_id integer,
    details json,
    PRIMARY KEY (att_conf_id, data_time),
    FOREIGN KEY (att_conf_id) REFERENCES att_conf (att_conf_id),
    FOREIGN KEY (att_error_desc_id) REFERENCES att_error_desc (att_error_desc_id)
);

COMMENT ON TABLE att_scalar_devenum IS 'Scalar Enum Values Table';
CREATE INDEX IF NOT EXISTS att_scalar_devenum_att_conf_id_idx ON att_scalar_devenum (att_conf_id);
CREATE INDEX IF NOT EXISTS att_scalar_devenum_att_conf_id_data_time_idx ON att_scalar_devenum (att_conf_id,data_time DESC);
SELECT create_hypertable('att_scalar_devenum', 'data_time', chunk_time_interval => interval '28 day', create_default_indexes => FALSE);

CREATE TABLE IF NOT EXISTS att_array_devenum (
    att_conf_id integer NOT NULL,
    data_time timestamp WITH TIME ZONE NOT NULL,
    value_r_label text[],
    value_r smallint[],
    value_w_label text[],
    value_w smallint[],
    quality smallint,
    att_error_desc_id integer,
    details json,
    PRIMARY KEY (att_conf_id, data_time),
    FOREIGN KEY (att_conf_id) REFERENCES att_conf (att_conf_id),
    FOREIGN KEY (att_error_desc_id) REFERENCES att_error_desc (att_error_desc_id)
);

COMMENT ON TABLE att_array_devenum IS 'Array Enum Values Table';
CREATE INDEX IF NOT EXISTS att_array_devenum_att_conf_id_idx ON att_array_devenum (att_conf_id);
CREATE INDEX IF NOT EXISTS att_array_devenum_att_conf_id_data_time_idx ON att_array_devenum (att_conf_id,data_time DESC);
SELECT create_hypertable('att_array_devenum', 'data_time', chunk_time_interval => interval '28 day', create_default_indexes => FALSE);

