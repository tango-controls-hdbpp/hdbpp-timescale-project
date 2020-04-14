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

-- Continuous aggregates views for the array attributes.

-- Double attributes
CREATE VIEW cagg_array_devdouble_1hour(
		att_conf_id, data_time, count_rows, count_errors
                , count_r, count_nan_r, mean_r, min_r, max_r, stddev_r
                , count_w, count_nan_w, mean_w, min_w, max_w, stddev_w
	) WITH (timescaledb.continuous, timescaledb.refresh_lag = '0 days', timescaledb.refresh_interval='1 hour')
       	AS SELECT att_conf_id, time_bucket('1 hour', data_time), (double_array_aggregate(t)).count,  (double_array_aggregate(t)).count_errors
        , (double_array_aggregate(t)).count_r,  (double_array_aggregate(t)).count_nan_r, (double_array_aggregate(t)).avg_r::float8[],  (double_array_aggregate(t)).min_r,  (double_array_aggregate(t)).max_r,  (double_array_aggregate(t)).stddev_r::float8[]  
        , (double_array_aggregate(t)).count_w,  (double_array_aggregate(t)).count_nan_w,  (double_array_aggregate(t)).avg_w::float8[], (double_array_aggregate(t)).min_w,  (double_array_aggregate(t)).max_w,  (double_array_aggregate(t)).stddev_w::float8[]  
       	FROM att_array_devdouble as t
                WHERE data_time > now() - interval '1 year' 
        GROUP BY time_bucket('1 hour', data_time), att_conf_id;

CREATE VIEW cagg_array_devdouble_8hour(
		att_conf_id, data_time, count_rows, count_errors
                , count_r, count_nan_r, mean_r, min_r, max_r, stddev_r
                , count_w, count_nan_w, mean_w, min_w, max_w, stddev_w
	) WITH (timescaledb.continuous, timescaledb.refresh_lag = '0 days', timescaledb.refresh_interval='8 hours')
       	AS SELECT att_conf_id, time_bucket('8 hours', data_time), (double_array_aggregate(t)).count,  (double_array_aggregate(t)).count_errors
        , (double_array_aggregate(t)).count_r,  (double_array_aggregate(t)).count_nan_r, (double_array_aggregate(t)).avg_r::float8[],  (double_array_aggregate(t)).min_r,  (double_array_aggregate(t)).max_r,  (double_array_aggregate(t)).stddev_r::float8[]  
        , (double_array_aggregate(t)).count_w,  (double_array_aggregate(t)).count_nan_w,  (double_array_aggregate(t)).avg_w::float8[], (double_array_aggregate(t)).min_w,  (double_array_aggregate(t)).max_w,  (double_array_aggregate(t)).stddev_w::float8[]  
       	FROM att_array_devdouble as t
                WHERE data_time > now() - interval '1 year' 
        GROUP BY time_bucket('8 hours', data_time), att_conf_id;

CREATE VIEW cagg_array_devdouble_1day(
		att_conf_id, data_time, count_rows, count_errors
                , count_r, count_nan_r, mean_r, min_r, max_r, stddev_r
                , count_w, count_nan_w, mean_w, min_w, max_w, stddev_w
	) WITH (timescaledb.continuous, timescaledb.refresh_lag = '0 days', timescaledb.refresh_interval='1 day')
       	AS SELECT att_conf_id, time_bucket('1 day', data_time), (double_array_aggregate(t)).count,  (double_array_aggregate(t)).count_errors
        , (double_array_aggregate(t)).count_r,  (double_array_aggregate(t)).count_nan_r, (double_array_aggregate(t)).avg_r::float8[],  (double_array_aggregate(t)).min_r,  (double_array_aggregate(t)).max_r,  (double_array_aggregate(t)).stddev_r::float8[]  
        , (double_array_aggregate(t)).count_w,  (double_array_aggregate(t)).count_nan_w,  (double_array_aggregate(t)).avg_w::float8[], (double_array_aggregate(t)).min_w,  (double_array_aggregate(t)).max_w,  (double_array_aggregate(t)).stddev_w::float8[]  
       	FROM att_array_devdouble as t
                WHERE data_time > now() - interval '1 year' 
        GROUP BY time_bucket('1 day', data_time), att_conf_id;

-- Float attributes
CREATE VIEW cagg_array_devfloat_1hour(
		att_conf_id, data_time, count_rows, count_errors
                , count_r, count_nan_r, mean_r, min_r, max_r, stddev_r
                , count_w, count_nan_w, mean_w, min_w, max_w, stddev_w
	) WITH (timescaledb.continuous, timescaledb.refresh_lag = '0 days', timescaledb.refresh_interval='1 hour')
       	AS SELECT att_conf_id, time_bucket('1 hour', data_time), (float_array_aggregate(t)).count,  (float_array_aggregate(t)).count_errors
        , (float_array_aggregate(t)).count_r,  (float_array_aggregate(t)).count_nan_r,  (float_array_aggregate(t)).avg_r::float8[], (float_array_aggregate(t)).min_r,  (float_array_aggregate(t)).max_r,  (float_array_aggregate(t)).stddev_r::float8[]  
        , (float_array_aggregate(t)).count_w,  (float_array_aggregate(t)).count_nan_w,  (float_array_aggregate(t)).avg_w::float8[], (float_array_aggregate(t)).min_w,  (float_array_aggregate(t)).max_w,  (float_array_aggregate(t)).stddev_w::float8[]  
       	FROM att_array_devfloat as t
                WHERE data_time > now() - interval '1 year' 
        GROUP BY time_bucket('1 hour', data_time), att_conf_id;

CREATE VIEW cagg_array_devfloat_8hour(
		att_conf_id, data_time, count_rows, count_errors
                , count_r, count_nan_r, mean_r, min_r, max_r, stddev_r
                , count_w, count_nan_w, mean_w, min_w, max_w, stddev_w
	) WITH (timescaledb.continuous, timescaledb.refresh_lag = '0 days', timescaledb.refresh_interval='8 hours')
       	AS SELECT att_conf_id, time_bucket('8 hours', data_time), (float_array_aggregate(t)).count,  (float_array_aggregate(t)).count_errors
        , (float_array_aggregate(t)).count_r,  (float_array_aggregate(t)).count_nan_r,  (float_array_aggregate(t)).avg_r::float8[], (float_array_aggregate(t)).min_r,  (float_array_aggregate(t)).max_r,  (float_array_aggregate(t)).stddev_r::float8[]  
        , (float_array_aggregate(t)).count_w,  (float_array_aggregate(t)).count_nan_w,  (float_array_aggregate(t)).avg_w::float8[], (float_array_aggregate(t)).min_w,  (float_array_aggregate(t)).max_w,  (float_array_aggregate(t)).stddev_w::float8[]  
       	FROM att_array_devfloat as t
                WHERE data_time > now() - interval '1 year' 
        GROUP BY time_bucket('8 hours', data_time), att_conf_id;

CREATE VIEW cagg_array_devfloat_1day(
		att_conf_id, data_time, count_rows, count_errors
                , count_r, count_nan_r, mean_r, min_r, max_r, stddev_r
                , count_w, count_nan_w, mean_w, min_w, max_w, stddev_w
	) WITH (timescaledb.continuous, timescaledb.refresh_lag = '0 days', timescaledb.refresh_interval='1 day')
       	AS SELECT att_conf_id, time_bucket('1 day', data_time), (float_array_aggregate(t)).count,  (float_array_aggregate(t)).count_errors
        , (float_array_aggregate(t)).count_r,  (float_array_aggregate(t)).count_nan_r,  (float_array_aggregate(t)).avg_r::float8[], (float_array_aggregate(t)).min_r,  (float_array_aggregate(t)).max_r,  (float_array_aggregate(t)).stddev_r::float8[]  
        , (float_array_aggregate(t)).count_w,  (float_array_aggregate(t)).count_nan_w,  (float_array_aggregate(t)).avg_w::float8[], (float_array_aggregate(t)).min_w,  (float_array_aggregate(t)).max_w,  (float_array_aggregate(t)).stddev_w::float8[]  
       	FROM att_array_devfloat as t
                WHERE data_time > now() - interval '1 year' 
        GROUP BY time_bucket('1 day', data_time), att_conf_id;

-- Long attributes
CREATE VIEW cagg_array_devlong_1hour(
		att_conf_id, data_time, count_rows, count_errors
                , count_r, mean_r, min_r, max_r, stddev_r
                , count_w, mean_w, min_w, max_w, stddev_w
	) WITH (timescaledb.continuous, timescaledb.refresh_lag = '0 days', timescaledb.refresh_interval='1 hour')
       	AS SELECT att_conf_id, time_bucket('1 hour', data_time), (long_array_aggregate(t)).count,  (long_array_aggregate(t)).count_errors
        , (long_array_aggregate(t)).count_r,  (long_array_aggregate(t)).avg_r::float8[], (long_array_aggregate(t)).min_r,  (long_array_aggregate(t)).max_r,  (long_array_aggregate(t)).stddev_r::float8[]  
        , (long_array_aggregate(t)).count_w,  (long_array_aggregate(t)).avg_w::float8[], (long_array_aggregate(t)).min_w,  (long_array_aggregate(t)).max_w,  (long_array_aggregate(t)).stddev_w::float8[]  
       	FROM att_array_devlong as t
                WHERE data_time > now() - interval '1 year' 
        GROUP BY time_bucket('1 hour', data_time), att_conf_id;

CREATE VIEW cagg_array_devlong_8hour(
		att_conf_id, data_time, count_rows, count_errors
                , count_r, mean_r, min_r, max_r, stddev_r
                , count_w, mean_w, min_w, max_w, stddev_w
	) WITH (timescaledb.continuous, timescaledb.refresh_lag = '0 days', timescaledb.refresh_interval='8 hours')
       	AS SELECT att_conf_id, time_bucket('8 hours', data_time), (long_array_aggregate(t)).count,  (long_array_aggregate(t)).count_errors
        , (long_array_aggregate(t)).count_r,  (long_array_aggregate(t)).avg_r::float8[], (long_array_aggregate(t)).min_r,  (long_array_aggregate(t)).max_r,  (long_array_aggregate(t)).stddev_r::float8[]  
        , (long_array_aggregate(t)).count_w,  (long_array_aggregate(t)).avg_w::float8[], (long_array_aggregate(t)).min_w,  (long_array_aggregate(t)).max_w,  (long_array_aggregate(t)).stddev_w::float8[]  
       	FROM att_array_devlong as t
                WHERE data_time > now() - interval '1 year' 
        GROUP BY time_bucket('8 hours', data_time), att_conf_id;

CREATE VIEW cagg_array_devlong_1day(
		att_conf_id, data_time, count_rows, count_errors
                , count_r, mean_r, min_r, max_r, stddev_r
                , count_w, mean_w, min_w, max_w, stddev_w
	) WITH (timescaledb.continuous, timescaledb.refresh_lag = '0 days', timescaledb.refresh_interval='1 day')
       	AS SELECT att_conf_id, time_bucket('1 day', data_time), (long_array_aggregate(t)).count,  (long_array_aggregate(t)).count_errors
        , (long_array_aggregate(t)).count_r, (long_array_aggregate(t)).avg_r::float8[], (long_array_aggregate(t)).min_r,  (long_array_aggregate(t)).max_r,  (long_array_aggregate(t)).stddev_r::float8[]  
        , (long_array_aggregate(t)).count_w, (long_array_aggregate(t)).avg_w::float8[], (long_array_aggregate(t)).min_w,  (long_array_aggregate(t)).max_w,  (long_array_aggregate(t)).stddev_w::float8[]  
       	FROM att_array_devlong as t
                WHERE data_time > now() - interval '1 year' 
        GROUP BY time_bucket('1 day', data_time), att_conf_id;

-- Long 64 attributes
CREATE VIEW cagg_array_devlong64_1hour(
		att_conf_id, data_time, count_rows, count_errors
                , count_r, mean_r, min_r, max_r, stddev_r
                , count_w, mean_w, min_w, max_w, stddev_w
	) WITH (timescaledb.continuous, timescaledb.refresh_lag = '0 days', timescaledb.refresh_interval='1 hour')
       	AS SELECT att_conf_id, time_bucket('1 hour', data_time), (long64_array_aggregate(t)).count,  (long64_array_aggregate(t)).count_errors
        , (long64_array_aggregate(t)).count_r,  (long64_array_aggregate(t)).avg_r::float8[], (long64_array_aggregate(t)).min_r,  (long64_array_aggregate(t)).max_r,  (long64_array_aggregate(t)).stddev_r::float8[]  
        , (long64_array_aggregate(t)).count_w,  (long64_array_aggregate(t)).avg_w::float8[], (long64_array_aggregate(t)).min_w,  (long64_array_aggregate(t)).max_w,  (long64_array_aggregate(t)).stddev_w::float8[]  
       	FROM att_array_devlong64 as t
                WHERE data_time > now() - interval '1 year' 
        GROUP BY time_bucket('1 hour', data_time), att_conf_id;

CREATE VIEW cagg_array_devlong64_8hour(
		att_conf_id, data_time, count_rows, count_errors
                , count_r, mean_r, min_r, max_r, stddev_r
                , count_w, mean_w, min_w, max_w, stddev_w
	) WITH (timescaledb.continuous, timescaledb.refresh_lag = '0 days', timescaledb.refresh_interval='8 hours')
       	AS SELECT att_conf_id, time_bucket('8 hours', data_time), (long64_array_aggregate(t)).count,  (long64_array_aggregate(t)).count_errors
        , (long64_array_aggregate(t)).count_r,  (long64_array_aggregate(t)).avg_r::float8[], (long64_array_aggregate(t)).min_r,  (long64_array_aggregate(t)).max_r,  (long64_array_aggregate(t)).stddev_r::float8[]  
        , (long64_array_aggregate(t)).count_w,  (long64_array_aggregate(t)).avg_w::float8[], (long64_array_aggregate(t)).min_w,  (long64_array_aggregate(t)).max_w,  (long64_array_aggregate(t)).stddev_w::float8[]  
       	FROM att_array_devlong64 as t
                WHERE data_time > now() - interval '1 year' 
        GROUP BY time_bucket('8 hours', data_time), att_conf_id;

CREATE VIEW cagg_array_devlong64_1day(
		att_conf_id, data_time, count_rows, count_errors
                , count_r, mean_r, min_r, max_r, stddev_r
                , count_w, mean_w, min_w, max_w, stddev_w
	) WITH (timescaledb.continuous, timescaledb.refresh_lag = '0 days', timescaledb.refresh_interval='1 day')
       	AS SELECT att_conf_id, time_bucket('1 day', data_time), (long64_array_aggregate(t)).count,  (long64_array_aggregate(t)).count_errors
        , (long64_array_aggregate(t)).count_r, (long64_array_aggregate(t)).avg_r::float8[], (long64_array_aggregate(t)).min_r,  (long64_array_aggregate(t)).max_r,  (long64_array_aggregate(t)).stddev_r::float8[]  
        , (long64_array_aggregate(t)).count_w, (long64_array_aggregate(t)).avg_w::float8[], (long64_array_aggregate(t)).min_w,  (long64_array_aggregate(t)).max_w,  (long64_array_aggregate(t)).stddev_w::float8[]  
       	FROM att_array_devlong64 as t
                WHERE data_time > now() - interval '1 year' 
        GROUP BY time_bucket('1 day', data_time), att_conf_id;

-- Short attributes
CREATE VIEW cagg_array_devshort_1hour(
		att_conf_id, data_time, count_rows, count_errors
                , count_r, mean_r, min_r, max_r, stddev_r
                , count_w, mean_w, min_w, max_w, stddev_w
	) WITH (timescaledb.continuous, timescaledb.refresh_lag = '0 days', timescaledb.refresh_interval='1 hour')
       	AS SELECT att_conf_id, time_bucket('1 hour', data_time), (short_array_aggregate(t)).count,  (short_array_aggregate(t)).count_errors
        , (short_array_aggregate(t)).count_r,  (short_array_aggregate(t)).avg_r::float8[], (short_array_aggregate(t)).min_r,  (short_array_aggregate(t)).max_r,  (short_array_aggregate(t)).stddev_r::float8[]  
        , (short_array_aggregate(t)).count_w,  (short_array_aggregate(t)).avg_w::float8[], (short_array_aggregate(t)).min_w,  (short_array_aggregate(t)).max_w,  (short_array_aggregate(t)).stddev_w::float8[]  
       	FROM att_array_devshort as t
                WHERE data_time > now() - interval '1 year' 
        GROUP BY time_bucket('1 hour', data_time), att_conf_id;

CREATE VIEW cagg_array_devshort_8hour(
		att_conf_id, data_time, count_rows, count_errors
                , count_r, mean_r, min_r, max_r, stddev_r
                , count_w, mean_w, min_w, max_w, stddev_w
	) WITH (timescaledb.continuous, timescaledb.refresh_lag = '0 days', timescaledb.refresh_interval='8 hours')
       	AS SELECT att_conf_id, time_bucket('8 hours', data_time), (short_array_aggregate(t)).count,  (short_array_aggregate(t)).count_errors
        , (short_array_aggregate(t)).count_r,  (short_array_aggregate(t)).avg_r::float8[], (short_array_aggregate(t)).min_r,  (short_array_aggregate(t)).max_r,  (short_array_aggregate(t)).stddev_r::float8[]  
        , (short_array_aggregate(t)).count_w,  (short_array_aggregate(t)).avg_w::float8[], (short_array_aggregate(t)).min_w,  (short_array_aggregate(t)).max_w,  (short_array_aggregate(t)).stddev_w::float8[]  
       	FROM att_array_devshort as t
                WHERE data_time > now() - interval '1 year' 
        GROUP BY time_bucket('8 hours', data_time), att_conf_id;

CREATE VIEW cagg_array_devshort_1day(
		att_conf_id, data_time, count_rows, count_errors
                , count_r, mean_r, min_r, max_r, stddev_r
                , count_w, mean_w, min_w, max_w, stddev_w
	) WITH (timescaledb.continuous, timescaledb.refresh_lag = '0 days', timescaledb.refresh_interval='1 day')
       	AS SELECT att_conf_id, time_bucket('1 day', data_time), (short_array_aggregate(t)).count,  (short_array_aggregate(t)).count_errors
        , (short_array_aggregate(t)).count_r, (short_array_aggregate(t)).avg_r::float8[], (short_array_aggregate(t)).min_r,  (short_array_aggregate(t)).max_r,  (short_array_aggregate(t)).stddev_r::float8[]  
        , (short_array_aggregate(t)).count_w, (short_array_aggregate(t)).avg_w::float8[], (short_array_aggregate(t)).min_w,  (short_array_aggregate(t)).max_w,  (short_array_aggregate(t)).stddev_w::float8[]  
       	FROM att_array_devshort as t
                WHERE data_time > now() - interval '1 year' 
        GROUP BY time_bucket('1 day', data_time), att_conf_id;

-- Unsigned long attributes
CREATE VIEW cagg_array_devulong_1hour(
		att_conf_id, data_time, count_rows, count_errors
                , count_r, mean_r, min_r, max_r, stddev_r
                , count_w, mean_w, min_w, max_w, stddev_w
	) WITH (timescaledb.continuous, timescaledb.refresh_lag = '0 days', timescaledb.refresh_interval='1 hour')
       	AS SELECT att_conf_id, time_bucket('1 hour', data_time), (ulong_array_aggregate(t)).count,  (ulong_array_aggregate(t)).count_errors
        , (ulong_array_aggregate(t)).count_r,  (ulong_array_aggregate(t)).avg_r::float8[], (ulong_array_aggregate(t)).min_r,  (ulong_array_aggregate(t)).max_r,  (ulong_array_aggregate(t)).stddev_r::float8[]  
        , (ulong_array_aggregate(t)).count_w,  (ulong_array_aggregate(t)).avg_w::float8[], (ulong_array_aggregate(t)).min_w,  (ulong_array_aggregate(t)).max_w,  (ulong_array_aggregate(t)).stddev_w::float8[]  
       	FROM att_array_devulong as t
                WHERE data_time > now() - interval '1 year' 
        GROUP BY time_bucket('1 hour', data_time), att_conf_id;

CREATE VIEW cagg_array_devulong_8hour(
		att_conf_id, data_time, count_rows, count_errors
                , count_r, mean_r, min_r, max_r, stddev_r
                , count_w, mean_w, min_w, max_w, stddev_w
	) WITH (timescaledb.continuous, timescaledb.refresh_lag = '0 days', timescaledb.refresh_interval='8 hours')
       	AS SELECT att_conf_id, time_bucket('8 hours', data_time), (ulong_array_aggregate(t)).count,  (ulong_array_aggregate(t)).count_errors
        , (ulong_array_aggregate(t)).count_r,  (ulong_array_aggregate(t)).avg_r::float8[], (ulong_array_aggregate(t)).min_r,  (ulong_array_aggregate(t)).max_r,  (ulong_array_aggregate(t)).stddev_r::float8[]  
        , (ulong_array_aggregate(t)).count_w,  (ulong_array_aggregate(t)).avg_w::float8[], (ulong_array_aggregate(t)).min_w,  (ulong_array_aggregate(t)).max_w,  (ulong_array_aggregate(t)).stddev_w::float8[]  
       	FROM att_array_devulong as t
                WHERE data_time > now() - interval '1 year' 
        GROUP BY time_bucket('8 hours', data_time), att_conf_id;

CREATE VIEW cagg_array_devulong_1day(
		att_conf_id, data_time, count_rows, count_errors
                , count_r, mean_r, min_r, max_r, stddev_r
                , count_w, mean_w, min_w, max_w, stddev_w
	) WITH (timescaledb.continuous, timescaledb.refresh_lag = '0 days', timescaledb.refresh_interval='1 day')
       	AS SELECT att_conf_id, time_bucket('1 day', data_time), (ulong_array_aggregate(t)).count,  (ulong_array_aggregate(t)).count_errors
        , (ulong_array_aggregate(t)).count_r, (ulong_array_aggregate(t)).avg_r::float8[], (ulong_array_aggregate(t)).min_r,  (ulong_array_aggregate(t)).max_r,  (ulong_array_aggregate(t)).stddev_r::float8[]  
        , (ulong_array_aggregate(t)).count_w, (ulong_array_aggregate(t)).avg_w::float8[], (ulong_array_aggregate(t)).min_w,  (ulong_array_aggregate(t)).max_w,  (ulong_array_aggregate(t)).stddev_w::float8[]  
       	FROM att_array_devulong as t
                WHERE data_time > now() - interval '1 year' 
        GROUP BY time_bucket('1 day', data_time), att_conf_id;

-- Unsigned long 64 attributes
CREATE VIEW cagg_array_devulong64_1hour(
		att_conf_id, data_time, count_rows, count_errors
                , count_r, mean_r, min_r, max_r, stddev_r
                , count_w, mean_w, min_w, max_w, stddev_w
	) WITH (timescaledb.continuous, timescaledb.refresh_lag = '0 days', timescaledb.refresh_interval='1 hour')
       	AS SELECT att_conf_id, time_bucket('1 hour', data_time), (ulong64_array_aggregate(t)).count,  (ulong64_array_aggregate(t)).count_errors
        , (ulong64_array_aggregate(t)).count_r,  (ulong64_array_aggregate(t)).avg_r::float8[], (ulong64_array_aggregate(t)).min_r,  (ulong64_array_aggregate(t)).max_r,  (ulong64_array_aggregate(t)).stddev_r::float8[]  
        , (ulong64_array_aggregate(t)).count_w,  (ulong64_array_aggregate(t)).avg_w::float8[], (ulong64_array_aggregate(t)).min_w,  (ulong64_array_aggregate(t)).max_w,  (ulong64_array_aggregate(t)).stddev_w::float8[]  
       	FROM att_array_devulong64 as t
                WHERE data_time > now() - interval '1 year' 
        GROUP BY time_bucket('1 hour', data_time), att_conf_id;

CREATE VIEW cagg_array_devulong64_8hour(
		att_conf_id, data_time, count_rows, count_errors
                , count_r, mean_r, min_r, max_r, stddev_r
                , count_w, mean_w, min_w, max_w, stddev_w
	) WITH (timescaledb.continuous, timescaledb.refresh_lag = '0 days', timescaledb.refresh_interval='8 hours')
       	AS SELECT att_conf_id, time_bucket('8 hours', data_time), (ulong64_array_aggregate(t)).count,  (ulong64_array_aggregate(t)).count_errors
        , (ulong64_array_aggregate(t)).count_r,  (ulong64_array_aggregate(t)).avg_r::float8[], (ulong64_array_aggregate(t)).min_r,  (ulong64_array_aggregate(t)).max_r,  (ulong64_array_aggregate(t)).stddev_r::float8[]  
        , (ulong64_array_aggregate(t)).count_w,  (ulong64_array_aggregate(t)).avg_w::float8[], (ulong64_array_aggregate(t)).min_w,  (ulong64_array_aggregate(t)).max_w,  (ulong64_array_aggregate(t)).stddev_w::float8[]  
       	FROM att_array_devulong64 as t
                WHERE data_time > now() - interval '1 year' 
        GROUP BY time_bucket('8 hours', data_time), att_conf_id;

CREATE VIEW cagg_array_devulong64_1day(
		att_conf_id, data_time, count_rows, count_errors
                , count_r, mean_r, min_r, max_r, stddev_r
                , count_w, mean_w, min_w, max_w, stddev_w
	) WITH (timescaledb.continuous, timescaledb.refresh_lag = '0 days', timescaledb.refresh_interval='1 day')
       	AS SELECT att_conf_id, time_bucket('1 day', data_time), (ulong64_array_aggregate(t)).count,  (ulong64_array_aggregate(t)).count_errors
        , (ulong64_array_aggregate(t)).count_r, (ulong64_array_aggregate(t)).avg_r::float8[], (ulong64_array_aggregate(t)).min_r,  (ulong64_array_aggregate(t)).max_r,  (ulong64_array_aggregate(t)).stddev_r::float8[]  
        , (ulong64_array_aggregate(t)).count_w, (ulong64_array_aggregate(t)).avg_w::float8[], (ulong64_array_aggregate(t)).min_w,  (ulong64_array_aggregate(t)).max_w,  (ulong64_array_aggregate(t)).stddev_w::float8[]  
       	FROM att_array_devulong64 as t
                WHERE data_time > now() - interval '1 year' 
        GROUP BY time_bucket('1 day', data_time), att_conf_id;

-- Unsigned short attributes
CREATE VIEW cagg_array_devushort_1hour(
		att_conf_id, data_time, count_rows, count_errors
                , count_r, mean_r, min_r, max_r, stddev_r
                , count_w, mean_w, min_w, max_w, stddev_w
	) WITH (timescaledb.continuous, timescaledb.refresh_lag = '0 days', timescaledb.refresh_interval='1 hour')
       	AS SELECT att_conf_id, time_bucket('1 hour', data_time), (ushort_array_aggregate(t)).count,  (ushort_array_aggregate(t)).count_errors
        , (ushort_array_aggregate(t)).count_r,  (ushort_array_aggregate(t)).avg_r::float8[], (ushort_array_aggregate(t)).min_r,  (ushort_array_aggregate(t)).max_r,  (ushort_array_aggregate(t)).stddev_r::float8[]  
        , (ushort_array_aggregate(t)).count_w,  (ushort_array_aggregate(t)).avg_w::float8[], (ushort_array_aggregate(t)).min_w,  (ushort_array_aggregate(t)).max_w,  (ushort_array_aggregate(t)).stddev_w::float8[]  
       	FROM att_array_devushort as t
                WHERE data_time > now() - interval '1 year' 
        GROUP BY time_bucket('1 hour', data_time), att_conf_id;

CREATE VIEW cagg_array_devushort_8hour(
		att_conf_id, data_time, count_rows, count_errors
                , count_r, mean_r, min_r, max_r, stddev_r
                , count_w, mean_w, min_w, max_w, stddev_w
	) WITH (timescaledb.continuous, timescaledb.refresh_lag = '0 days', timescaledb.refresh_interval='8 hours')
       	AS SELECT att_conf_id, time_bucket('8 hours', data_time), (ushort_array_aggregate(t)).count,  (ushort_array_aggregate(t)).count_errors
        , (ushort_array_aggregate(t)).count_r,  (ushort_array_aggregate(t)).avg_r::float8[], (ushort_array_aggregate(t)).min_r,  (ushort_array_aggregate(t)).max_r,  (ushort_array_aggregate(t)).stddev_r::float8[]  
        , (ushort_array_aggregate(t)).count_w,  (ushort_array_aggregate(t)).avg_w::float8[], (ushort_array_aggregate(t)).min_w,  (ushort_array_aggregate(t)).max_w,  (ushort_array_aggregate(t)).stddev_w::float8[]  
       	FROM att_array_devushort as t
                WHERE data_time > now() - interval '1 year' 
        GROUP BY time_bucket('8 hours', data_time), att_conf_id;

CREATE VIEW cagg_array_devushort_1day(
		att_conf_id, data_time, count_rows, count_errors
                , count_r, mean_r, min_r, max_r, stddev_r
                , count_w, mean_w, min_w, max_w, stddev_w
	) WITH (timescaledb.continuous, timescaledb.refresh_lag = '0 days', timescaledb.refresh_interval='1 day')
       	AS SELECT att_conf_id, time_bucket('1 day', data_time), (ushort_array_aggregate(t)).count,  (ushort_array_aggregate(t)).count_errors
        , (ushort_array_aggregate(t)).count_r, (ushort_array_aggregate(t)).avg_r::float8[], (ushort_array_aggregate(t)).min_r,  (ushort_array_aggregate(t)).max_r,  (ushort_array_aggregate(t)).stddev_r::float8[]  
        , (ushort_array_aggregate(t)).count_w, (ushort_array_aggregate(t)).avg_w::float8[], (ushort_array_aggregate(t)).min_w,  (ushort_array_aggregate(t)).max_w,  (ushort_array_aggregate(t)).stddev_w::float8[]  
       	FROM att_array_devushort as t
                WHERE data_time > now() - interval '1 year' 
        GROUP BY time_bucket('1 day', data_time), att_conf_id;

-- Drop all the views
-- DROP VIEW cagg_array_devdouble_1hour CASCADE;
-- DROP VIEW cagg_array_devdouble_8hour CASCADE;
-- DROP VIEW cagg_array_devdouble_1day CASCADE;

-- DROP VIEW cagg_array_devfloat_1hour CASCADE;
-- DROP VIEW cagg_array_devfloat_8hour CASCADE;
-- DROP VIEW cagg_array_devfloat_1day CASCADE;

-- DROP VIEW cagg_array_devlong_1hour CASCADE;
-- DROP VIEW cagg_array_devlong_8hour CASCADE;
-- DROP VIEW cagg_array_devlong_1day CASCADE;

-- DROP VIEW cagg_array_devlong64_1hour CASCADE;
-- DROP VIEW cagg_array_devlong64_8hour CASCADE;
-- DROP VIEW cagg_array_devlong64_1day CASCADE;

-- DROP VIEW cagg_array_devshort_1hour CASCADE;
-- DROP VIEW cagg_array_devshort_8hour CASCADE;
-- DROP VIEW cagg_array_devshort_1day CASCADE;

-- DROP VIEW cagg_array_devulong_1hour CASCADE;
-- DROP VIEW cagg_array_devulong_8hour CASCADE;
-- DROP VIEW cagg_array_devulong_1day CASCADE;

-- DROP VIEW cagg_array_devulong64_1hour CASCADE;
-- DROP VIEW cagg_array_devulong64_8hour CASCADE;
-- DROP VIEW cagg_array_devulong64_1day CASCADE;

-- DROP VIEW cagg_array_devushort_1hour CASCADE;
-- DROP VIEW cagg_array_devushort_8hour CASCADE;
-- DROP VIEW cagg_array_devushort_1day CASCADE;

