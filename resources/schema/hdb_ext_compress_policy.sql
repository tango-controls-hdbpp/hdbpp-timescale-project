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

-- Compress chunk policy
-- Allow compression on the table
ALTER TABLE att_scalar_devboolean SET(timescaledb.compress, timescaledb.compress_segmentby = 'att_conf_id, att_error_desc_id', timescaledb.compress_orderby = 'data_time DESC');
ALTER TABLE att_scalar_devdouble SET(timescaledb.compress, timescaledb.compress_segmentby = 'att_conf_id, att_error_desc_id', timescaledb.compress_orderby = 'data_time DESC');
ALTER TABLE att_scalar_devfloat SET(timescaledb.compress, timescaledb.compress_segmentby = 'att_conf_id, att_error_desc_id', timescaledb.compress_orderby = 'data_time DESC');
ALTER TABLE att_scalar_devencoded SET(timescaledb.compress, timescaledb.compress_segmentby = 'att_conf_id, att_error_desc_id', timescaledb.compress_orderby = 'data_time DESC');
ALTER TABLE att_scalar_devenum SET(timescaledb.compress, timescaledb.compress_segmentby = 'att_conf_id, att_error_desc_id', timescaledb.compress_orderby = 'data_time DESC');
ALTER TABLE att_scalar_devstate SET(timescaledb.compress, timescaledb.compress_segmentby = 'att_conf_id, att_error_desc_id', timescaledb.compress_orderby = 'data_time DESC');
ALTER TABLE att_scalar_devstring SET(timescaledb.compress, timescaledb.compress_segmentby = 'att_conf_id, att_error_desc_id', timescaledb.compress_orderby = 'data_time DESC');
ALTER TABLE att_scalar_devuchar SET(timescaledb.compress, timescaledb.compress_segmentby = 'att_conf_id, att_error_desc_id', timescaledb.compress_orderby = 'data_time DESC');
ALTER TABLE att_scalar_devulong SET(timescaledb.compress, timescaledb.compress_segmentby = 'att_conf_id, att_error_desc_id', timescaledb.compress_orderby = 'data_time DESC');
ALTER TABLE att_scalar_devulong64 SET(timescaledb.compress, timescaledb.compress_segmentby = 'att_conf_id, att_error_desc_id', timescaledb.compress_orderby = 'data_time DESC');
ALTER TABLE att_scalar_devlong64 SET(timescaledb.compress, timescaledb.compress_segmentby = 'att_conf_id, att_error_desc_id', timescaledb.compress_orderby = 'data_time DESC');
ALTER TABLE att_scalar_devlong SET(timescaledb.compress, timescaledb.compress_segmentby = 'att_conf_id, att_error_desc_id', timescaledb.compress_orderby = 'data_time DESC');
ALTER TABLE att_scalar_devushort SET(timescaledb.compress, timescaledb.compress_segmentby = 'att_conf_id, att_error_desc_id', timescaledb.compress_orderby = 'data_time DESC');
ALTER TABLE att_scalar_devshort SET(timescaledb.compress, timescaledb.compress_segmentby = 'att_conf_id, att_error_desc_id', timescaledb.compress_orderby = 'data_time DESC');

ALTER TABLE att_array_devboolean SET(timescaledb.compress, timescaledb.compress_segmentby = 'att_conf_id, att_error_desc_id', timescaledb.compress_orderby = 'data_time DESC');
ALTER TABLE att_array_devdouble SET(timescaledb.compress, timescaledb.compress_segmentby = 'att_conf_id, att_error_desc_id', timescaledb.compress_orderby = 'data_time DESC');
ALTER TABLE att_array_devfloat SET(timescaledb.compress, timescaledb.compress_segmentby = 'att_conf_id, att_error_desc_id', timescaledb.compress_orderby = 'data_time DESC');
ALTER TABLE att_array_devencoded SET(timescaledb.compress, timescaledb.compress_segmentby = 'att_conf_id, att_error_desc_id', timescaledb.compress_orderby = 'data_time DESC');
ALTER TABLE att_array_devenum SET(timescaledb.compress, timescaledb.compress_segmentby = 'att_conf_id, att_error_desc_id', timescaledb.compress_orderby = 'data_time DESC');
ALTER TABLE att_array_devstate SET(timescaledb.compress, timescaledb.compress_segmentby = 'att_conf_id, att_error_desc_id', timescaledb.compress_orderby = 'data_time DESC');
ALTER TABLE att_array_devstring SET(timescaledb.compress, timescaledb.compress_segmentby = 'att_conf_id, att_error_desc_id', timescaledb.compress_orderby = 'data_time DESC');
ALTER TABLE att_array_devuchar SET(timescaledb.compress, timescaledb.compress_segmentby = 'att_conf_id, att_error_desc_id', timescaledb.compress_orderby = 'data_time DESC');
ALTER TABLE att_array_devulong SET(timescaledb.compress, timescaledb.compress_segmentby = 'att_conf_id, att_error_desc_id', timescaledb.compress_orderby = 'data_time DESC');
ALTER TABLE att_array_devulong64 SET(timescaledb.compress, timescaledb.compress_segmentby = 'att_conf_id, att_error_desc_id', timescaledb.compress_orderby = 'data_time DESC');
ALTER TABLE att_array_devlong64 SET(timescaledb.compress, timescaledb.compress_segmentby = 'att_conf_id, att_error_desc_id', timescaledb.compress_orderby = 'data_time DESC');
ALTER TABLE att_array_devlong SET(timescaledb.compress, timescaledb.compress_segmentby = 'att_conf_id, att_error_desc_id', timescaledb.compress_orderby = 'data_time DESC');
ALTER TABLE att_array_devushort SET(timescaledb.compress, timescaledb.compress_segmentby = 'att_conf_id, att_error_desc_id', timescaledb.compress_orderby = 'data_time DESC');
ALTER TABLE att_array_devshort SET(timescaledb.compress, timescaledb.compress_segmentby = 'att_conf_id, att_error_desc_id', timescaledb.compress_orderby = 'data_time DESC');

-- If using timescaledb v1.7
SELECT add_compress_chunks_policy('att_scalar_devboolean', INTERVAL '200d', if_not_exists => true);
SELECT add_compress_chunks_policy('att_scalar_devdouble', INTERVAL '200d', if_not_exists => true);
SELECT add_compress_chunks_policy('att_scalar_devfloat', INTERVAL '200d', if_not_exists => true);
SELECT add_compress_chunks_policy('att_scalar_devencoded', INTERVAL '200d', if_not_exists => true);
SELECT add_compress_chunks_policy('att_scalar_devenum', INTERVAL '200d', if_not_exists => true);
SELECT add_compress_chunks_policy('att_scalar_devstate', INTERVAL '200d', if_not_exists => true);
SELECT add_compress_chunks_policy('att_scalar_devstring', INTERVAL '200d', if_not_exists => true);
SELECT add_compress_chunks_policy('att_scalar_devuchar', INTERVAL '200d', if_not_exists => true);
SELECT add_compress_chunks_policy('att_scalar_devulong', INTERVAL '200d', if_not_exists => true);
SELECT add_compress_chunks_policy('att_scalar_devulong64', INTERVAL '200d', if_not_exists => true);
SELECT add_compress_chunks_policy('att_scalar_devlong64', INTERVAL '200d', if_not_exists => true);
SELECT add_compress_chunks_policy('att_scalar_devlong', INTERVAL '200d', if_not_exists => true);
SELECT add_compress_chunks_policy('att_scalar_devushort', INTERVAL '200d', if_not_exists => true);
SELECT add_compress_chunks_policy('att_scalar_devshort', INTERVAL '200d', if_not_exists => true);

SELECT add_compress_chunks_policy('att_array_devboolean', INTERVAL '200d', if_not_exists => true);
SELECT add_compress_chunks_policy('att_array_devdouble', INTERVAL '200d', if_not_exists => true);
SELECT add_compress_chunks_policy('att_array_devfloat', INTERVAL '200d', if_not_exists => true);
SELECT add_compress_chunks_policy('att_array_devencoded', INTERVAL '200d', if_not_exists => true);
SELECT add_compress_chunks_policy('att_array_devenum', INTERVAL '200d', if_not_exists => true);
SELECT add_compress_chunks_policy('att_array_devstate', INTERVAL '200d', if_not_exists => true);
SELECT add_compress_chunks_policy('att_array_devstring', INTERVAL '200d', if_not_exists => true);
SELECT add_compress_chunks_policy('att_array_devuchar', INTERVAL '200d', if_not_exists => true);
SELECT add_compress_chunks_policy('att_array_devulong', INTERVAL '200d', if_not_exists => true);
SELECT add_compress_chunks_policy('att_array_devulong64', INTERVAL '200d', if_not_exists => true);
SELECT add_compress_chunks_policy('att_array_devlong64', INTERVAL '200d', if_not_exists => true);
SELECT add_compress_chunks_policy('att_array_devlong', INTERVAL '200d', if_not_exists => true);
SELECT add_compress_chunks_policy('att_array_devushort', INTERVAL '200d', if_not_exists => true);
SELECT add_compress_chunks_policy('att_array_devshort', INTERVAL '200d', if_not_exists => true);

-- If using timescaledb v2
-- SELECT add_compression_policy('att_scalar_devboolean', INTERVAL '200d', if_not_exists => true);
-- SELECT add_compression_policy('att_scalar_devdouble', INTERVAL '200d', if_not_exists => true);
-- SELECT add_compression_policy('att_scalar_devfloat', INTERVAL '200d', if_not_exists => true);
-- SELECT add_compression_policy('att_scalar_devencoded', INTERVAL '200d', if_not_exists => true);
-- SELECT add_compression_policy('att_scalar_devenum', INTERVAL '200d', if_not_exists => true);
-- SELECT add_compression_policy('att_scalar_devstate', INTERVAL '200d', if_not_exists => true);
-- SELECT add_compression_policy('att_scalar_devstring', INTERVAL '200d', if_not_exists => true);
-- SELECT add_compression_policy('att_scalar_devuchar', INTERVAL '200d', if_not_exists => true);
-- SELECT add_compression_policy('att_scalar_devulong', INTERVAL '200d', if_not_exists => true);
-- SELECT add_compression_policy('att_scalar_devulong64', INTERVAL '200d', if_not_exists => true);
-- SELECT add_compression_policy('att_scalar_devlong64', INTERVAL '200d', if_not_exists => true);
-- SELECT add_compression_policy('att_scalar_devlong', INTERVAL '200d', if_not_exists => true);
-- SELECT add_compression_policy('att_scalar_devushort', INTERVAL '200d', if_not_exists => true);
-- SELECT add_compression_policy('att_scalar_devshort', INTERVAL '200d', if_not_exists => true);

-- SELECT add_compression_policy('att_array_devboolean', INTERVAL '200d', if_not_exists => true);
-- SELECT add_compression_policy('att_array_devdouble', INTERVAL '200d', if_not_exists => true);
-- SELECT add_compression_policy('att_array_devfloat', INTERVAL '200d', if_not_exists => true);
-- SELECT add_compression_policy('att_array_devencoded', INTERVAL '200d', if_not_exists => true);
-- SELECT add_compression_policy('att_array_devenum', INTERVAL '200d', if_not_exists => true);
-- SELECT add_compression_policy('att_array_devstate', INTERVAL '200d', if_not_exists => true);
-- SELECT add_compression_policy('att_array_devstring', INTERVAL '200d', if_not_exists => true);
-- SELECT add_compression_policy('att_array_devuchar', INTERVAL '200d', if_not_exists => true);
-- SELECT add_compression_policy('att_array_devulong', INTERVAL '200d', if_not_exists => true);
-- SELECT add_compression_policy('att_array_devulong64', INTERVAL '200d', if_not_exists => true);
-- SELECT add_compression_policy('att_array_devlong64', INTERVAL '200d', if_not_exists => true);
-- SELECT add_compression_policy('att_array_devlong', INTERVAL '200d', if_not_exists => true);
-- SELECT add_compression_policy('att_array_devushort', INTERVAL '200d', if_not_exists => true);
-- SELECT add_compression_policy('att_array_devshort', INTERVAL '200d', if_not_exists => true);
