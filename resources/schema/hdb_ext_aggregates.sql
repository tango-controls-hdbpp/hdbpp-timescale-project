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

-- Continuous aggregates views for the attributes.

-- Double attributes
CREATE VIEW cagg_scalar_devdouble_1min(
		att_conf_id, data_time, count_rows, count_errors
		, count_r, mean_r, min_r, max_r, stddev_r
		, count_w, mean_w, min_w, max_w, stddev_w
	) WITH (timescaledb.continuous, timescaledb.refresh_lag = '0 days', timescaledb.refresh_interval='1 min')
       	AS SELECT att_conf_id, time_bucket('1 min', data_time), count(*), count(att_error_desc_id)
		, count(value_r), avg(value_r), min(value_r), max(value_r), stddev(value_r)
		, count(value_w), avg(value_w), min(value_w), max(value_w), stddev(value_w)
       	FROM att_scalar_devdouble
       	        WHERE data_time > now() - interval '1 year'
        GROUP BY time_bucket('1 min', data_time), att_conf_id;

CREATE VIEW cagg_scalar_devdouble_10min(
		att_conf_id, data_time, count_rows, count_errors
		, count_r, mean_r, min_r, max_r, stddev_r
		, count_w, mean_w, min_w, max_w, stddev_w
	) WITH (timescaledb.continuous, timescaledb.refresh_lag = '0 days', timescaledb.refresh_interval='10 mins')
       	AS SELECT att_conf_id, time_bucket('10 mins', data_time), count(*), count(att_error_desc_id)
		, count(value_r), avg(value_r), min(value_r), max(value_r), stddev(value_r)
		, count(value_w), avg(value_w), min(value_w), max(value_w), stddev(value_w)
       	FROM att_scalar_devdouble
                WHERE data_time > now() - interval '1 year'
        GROUP BY time_bucket('10 mins', data_time), att_conf_id;

CREATE VIEW cagg_scalar_devdouble_1hour(
		att_conf_id, data_time, count_rows, count_errors
		, count_r, mean_r, min_r, max_r, stddev_r
		, count_w, mean_w, min_w, max_w, stddev_w
	) WITH (timescaledb.continuous, timescaledb.refresh_lag = '0 days', timescaledb.refresh_interval='1 hour')
       	AS SELECT att_conf_id, time_bucket('1 hour', data_time), count(*), count(att_error_desc_id)
		, count(value_r), avg(value_r), min(value_r), max(value_r), stddev(value_r)
		, count(value_w), avg(value_w), min(value_w), max(value_w), stddev(value_w)
       	FROM att_scalar_devdouble 
                WHERE data_time > now() - interval '1 year' 
        GROUP BY time_bucket('1 hour', data_time), att_conf_id;

CREATE VIEW cagg_scalar_devdouble_8hour(
		att_conf_id, data_time, count_rows, count_errors
		, count_r, mean_r, min_r, max_r, stddev_r
		, count_w, mean_w, min_w, max_w, stddev_w
	) WITH (timescaledb.continuous, timescaledb.refresh_lag = '0 days', timescaledb.refresh_interval='8 hours')
       	AS SELECT att_conf_id, time_bucket('8 hours', data_time), count(*), count(att_error_desc_id)
		, count(value_r), avg(value_r), min(value_r), max(value_r), stddev(value_r)
		, count(value_w), avg(value_w), min(value_w), max(value_w), stddev(value_w)
       	FROM att_scalar_devdouble 
                WHERE data_time > now() - interval '1 year' 
        GROUP BY time_bucket('8 hours', data_time), att_conf_id;

CREATE VIEW cagg_scalar_devdouble_1day(
		att_conf_id, data_time, count_rows, count_errors
		, count_r, mean_r, min_r, max_r, stddev_r
		, count_w, mean_w, min_w, max_w, stddev_w
	) WITH (timescaledb.continuous, timescaledb.refresh_lag = '0 days', timescaledb.refresh_interval='1 day')
       	AS SELECT att_conf_id, time_bucket('1 day', data_time), count(*), count(att_error_desc_id)
		, count(value_r), avg(value_r), min(value_r), max(value_r), stddev(value_r)
		, count(value_w), avg(value_w), min(value_w), max(value_w), stddev(value_w)
       	FROM att_scalar_devdouble 
                WHERE data_time > now() - interval '1 year' 
        GROUP BY time_bucket('1 day', data_time), att_conf_id;

-- Float attributes
CREATE VIEW cagg_scalar_devfloat_1min(
		att_conf_id, data_time, count_rows, count_errors
		, count_r, mean_r, min_r, max_r, stddev_r
		, count_w, mean_w, min_w, max_w, stddev_w
	) WITH (timescaledb.continuous, timescaledb.refresh_lag = '0 days', timescaledb.refresh_interval='1 min')
       	AS SELECT att_conf_id, time_bucket('1 min', data_time), count(*), count(att_error_desc_id)
		, count(value_r), avg(value_r), min(value_r), max(value_r), stddev(value_r)
		, count(value_w), avg(value_w), min(value_w), max(value_w), stddev(value_w)
       	FROM att_scalar_devfloat 
                WHERE data_time > now() - interval '1 year' 
        GROUP BY time_bucket('1 min', data_time), att_conf_id;

CREATE VIEW cagg_scalar_devfloat_10min(
		att_conf_id, data_time, count_rows, count_errors
		, count_r, mean_r, min_r, max_r, stddev_r
		, count_w, mean_w, min_w, max_w, stddev_w
	) WITH (timescaledb.continuous, timescaledb.refresh_lag = '0 days', timescaledb.refresh_interval='10 mins')
       	AS SELECT att_conf_id, time_bucket('10 mins', data_time), count(*), count(att_error_desc_id)
		, count(value_r), avg(value_r), min(value_r), max(value_r), stddev(value_r)
		, count(value_w), avg(value_w), min(value_w), max(value_w), stddev(value_w)
       	FROM att_scalar_devfloat 
                WHERE data_time > now() - interval '1 year' 
        GROUP BY time_bucket('10 mins', data_time), att_conf_id;

CREATE VIEW cagg_scalar_devfloat_1hour(
		att_conf_id, data_time, count_rows, count_errors
		, count_r, mean_r, min_r, max_r, stddev_r
		, count_w, mean_w, min_w, max_w, stddev_w
	) WITH (timescaledb.continuous, timescaledb.refresh_lag = '0 days', timescaledb.refresh_interval='1 hour')
       	AS SELECT att_conf_id, time_bucket('1 hour', data_time), count(*), count(att_error_desc_id)
		, count(value_r), avg(value_r), min(value_r), max(value_r), stddev(value_r)
		, count(value_w), avg(value_w), min(value_w), max(value_w), stddev(value_w)
       	FROM att_scalar_devfloat 
                WHERE data_time > now() - interval '1 year' 
        GROUP BY time_bucket('1 hour', data_time), att_conf_id;

CREATE VIEW cagg_scalar_devfloat_8hour(
		att_conf_id, data_time, count_rows, count_errors
		, count_r, mean_r, min_r, max_r, stddev_r
		, count_w, mean_w, min_w, max_w, stddev_w
	) WITH (timescaledb.continuous, timescaledb.refresh_lag = '0 days', timescaledb.refresh_interval='8 hours')
       	AS SELECT att_conf_id, time_bucket('8 hours', data_time), count(*), count(att_error_desc_id)
		, count(value_r), avg(value_r), min(value_r), max(value_r), stddev(value_r)
		, count(value_w), avg(value_w), min(value_w), max(value_w), stddev(value_w)
       	FROM att_scalar_devfloat 
                WHERE data_time > now() - interval '1 year' 
        GROUP BY time_bucket('8 hours', data_time), att_conf_id;

CREATE VIEW cagg_scalar_devfloat_1day(
		att_conf_id, data_time, count_rows, count_errors
		, count_r, mean_r, min_r, max_r, stddev_r
		, count_w, mean_w, min_w, max_w, stddev_w
	) WITH (timescaledb.continuous, timescaledb.refresh_lag = '0 days', timescaledb.refresh_interval='1 day')
       	AS SELECT att_conf_id, time_bucket('1 day', data_time), count(*), count(att_error_desc_id)
		, count(value_r), avg(value_r), min(value_r), max(value_r), stddev(value_r)
		, count(value_w), avg(value_w), min(value_w), max(value_w), stddev(value_w)
       	FROM att_scalar_devfloat 
                WHERE data_time > now() - interval '1 year' 
        GROUP BY time_bucket('1 day', data_time), att_conf_id;

-- Long Attributes
CREATE VIEW cagg_scalar_devlong_1min(
		att_conf_id, data_time, count_rows, count_errors
		, count_r, mean_r, min_r, max_r, stddev_r
		, count_w, mean_w, min_w, max_w, stddev_w
	) WITH (timescaledb.continuous, timescaledb.refresh_lag = '0 days', timescaledb.refresh_interval='1 min')
       	AS SELECT att_conf_id, time_bucket('1 min', data_time), count(*), count(att_error_desc_id)
		, count(value_r), avg(value_r), min(value_r), max(value_r), stddev(value_r)
		, count(value_w), avg(value_w), min(value_w), max(value_w), stddev(value_w)
       	FROM att_scalar_devlong         
                WHERE data_time > now() - interval '1 year' 
        GROUP BY time_bucket('1 min', data_time), att_conf_id;

CREATE VIEW cagg_scalar_devlong_10min(
		att_conf_id, data_time, count_rows, count_errors
		, count_r, mean_r, min_r, max_r, stddev_r
		, count_w, mean_w, min_w, max_w, stddev_w
	) WITH (timescaledb.continuous, timescaledb.refresh_lag = '0 days', timescaledb.refresh_interval='10 mins')
       	AS SELECT att_conf_id, time_bucket('10 mins', data_time), count(*), count(att_error_desc_id)
		, count(value_r), avg(value_r), min(value_r), max(value_r), stddev(value_r)
		, count(value_w), avg(value_w), min(value_w), max(value_w), stddev(value_w)
       	FROM att_scalar_devlong 
                WHERE data_time > now() - interval '1 year' 
        GROUP BY time_bucket('10 mins', data_time), att_conf_id;

CREATE VIEW cagg_scalar_devlong_1hour(
		att_conf_id, data_time, count_rows, count_errors
		, count_r, mean_r, min_r, max_r, stddev_r
		, count_w, mean_w, min_w, max_w, stddev_w
	) WITH (timescaledb.continuous, timescaledb.refresh_lag = '0 days', timescaledb.refresh_interval='1 hour')
       	AS SELECT att_conf_id, time_bucket('1 hour', data_time), count(*), count(att_error_desc_id)
		, count(value_r), avg(value_r), min(value_r), max(value_r), stddev(value_r)
		, count(value_w), avg(value_w), min(value_w), max(value_w), stddev(value_w)
       	FROM att_scalar_devlong 
                WHERE data_time > now() - interval '1 year' 
        GROUP BY time_bucket('1 hour', data_time), att_conf_id;

CREATE VIEW cagg_scalar_devlong_8hour(
		att_conf_id, data_time, count_rows, count_errors
		, count_r, mean_r, min_r, max_r, stddev_r
		, count_w, mean_w, min_w, max_w, stddev_w
	) WITH (timescaledb.continuous, timescaledb.refresh_lag = '0 days', timescaledb.refresh_interval='8 hours')
       	AS SELECT att_conf_id, time_bucket('8 hours', data_time), count(*), count(att_error_desc_id)
		, count(value_r), avg(value_r), min(value_r), max(value_r), stddev(value_r)
		, count(value_w), avg(value_w), min(value_w), max(value_w), stddev(value_w)
       	FROM att_scalar_devlong 
                WHERE data_time > now() - interval '1 year' 
        GROUP BY time_bucket('8 hours', data_time), att_conf_id;

CREATE VIEW cagg_scalar_devlong_1day(
		att_conf_id, data_time, count_rows, count_errors
		, count_r, mean_r, min_r, max_r, stddev_r
		, count_w, mean_w, min_w, max_w, stddev_w
	) WITH (timescaledb.continuous, timescaledb.refresh_lag = '0 days', timescaledb.refresh_interval='1 day')
       	AS SELECT att_conf_id, time_bucket('1 day', data_time), count(*), count(att_error_desc_id)
		, count(value_r), avg(value_r), min(value_r), max(value_r), stddev(value_r)
		, count(value_w), avg(value_w), min(value_w), max(value_w), stddev(value_w)
       	FROM att_scalar_devlong 
                WHERE data_time > now() - interval '1 year' 
        GROUP BY time_bucket('1 day', data_time), att_conf_id;

-- Long 64 attributes
CREATE VIEW cagg_scalar_devlong64_1min(
		att_conf_id, data_time, count_rows, count_errors
		, count_r, mean_r, min_r, max_r, stddev_r
		, count_w, mean_w, min_w, max_w, stddev_w
	) WITH (timescaledb.continuous, timescaledb.refresh_lag = '0 days', timescaledb.refresh_interval='1 min')
       	AS SELECT att_conf_id, time_bucket('1 min', data_time), count(*), count(att_error_desc_id)
		, count(value_r), avg(value_r), min(value_r), max(value_r), stddev(value_r)
		, count(value_w), avg(value_w), min(value_w), max(value_w), stddev(value_w)
       	FROM att_scalar_devlong64 
                WHERE data_time > now() - interval '1 year' 
        GROUP BY time_bucket('1 min', data_time), att_conf_id;

CREATE VIEW cagg_scalar_devlong64_10min(
		att_conf_id, data_time, count_rows, count_errors
		, count_r, mean_r, min_r, max_r, stddev_r
		, count_w, mean_w, min_w, max_w, stddev_w
	) WITH (timescaledb.continuous, timescaledb.refresh_lag = '0 days', timescaledb.refresh_interval='10 mins')
       	AS SELECT att_conf_id, time_bucket('10 mins', data_time), count(*), count(att_error_desc_id)
		, count(value_r), avg(value_r), min(value_r), max(value_r), stddev(value_r)
		, count(value_w), avg(value_w), min(value_w), max(value_w), stddev(value_w)
       	FROM att_scalar_devlong64 
                WHERE data_time > now() - interval '1 year' 
        GROUP BY time_bucket('10 mins', data_time), att_conf_id;

CREATE VIEW cagg_scalar_devlong64_1hour(
		att_conf_id, data_time, count_rows, count_errors
		, count_r, mean_r, min_r, max_r, stddev_r
		, count_w, mean_w, min_w, max_w, stddev_w
	) WITH (timescaledb.continuous, timescaledb.refresh_lag = '0 days', timescaledb.refresh_interval='1 hour')
       	AS SELECT att_conf_id, time_bucket('1 hour', data_time), count(*), count(att_error_desc_id)
		, count(value_r), avg(value_r), min(value_r), max(value_r), stddev(value_r)
		, count(value_w), avg(value_w), min(value_w), max(value_w), stddev(value_w)
       	FROM att_scalar_devlong64 
                WHERE data_time > now() - interval '1 year' 
        GROUP BY time_bucket('1 hour', data_time), att_conf_id;

CREATE VIEW cagg_scalar_devlong64_8hour(
		att_conf_id, data_time, count_rows, count_errors
		, count_r, mean_r, min_r, max_r, stddev_r
		, count_w, mean_w, min_w, max_w, stddev_w
	) WITH (timescaledb.continuous, timescaledb.refresh_lag = '0 days', timescaledb.refresh_interval='8 hours')
       	AS SELECT att_conf_id, time_bucket('8 hours', data_time), count(*), count(att_error_desc_id)
		, count(value_r), avg(value_r), min(value_r), max(value_r), stddev(value_r)
		, count(value_w), avg(value_w), min(value_w), max(value_w), stddev(value_w)
       	FROM att_scalar_devlong64 
                WHERE data_time > now() - interval '1 year' 
        GROUP BY time_bucket('8 hours', data_time), att_conf_id;

CREATE VIEW cagg_scalar_devlong64_1day(
		att_conf_id, data_time, count_rows, count_errors
		, count_r, mean_r, min_r, max_r, stddev_r
		, count_w, mean_w, min_w, max_w, stddev_w
	) WITH (timescaledb.continuous, timescaledb.refresh_lag = '0 days', timescaledb.refresh_interval='1 day')
       	AS SELECT att_conf_id, time_bucket('1 day', data_time), count(*), count(att_error_desc_id)
		, count(value_r), avg(value_r), min(value_r), max(value_r), stddev(value_r)
		, count(value_w), avg(value_w), min(value_w), max(value_w), stddev(value_w)
       	FROM att_scalar_devlong64 
                WHERE data_time > now() - interval '1 year' 
        GROUP BY time_bucket('1 day', data_time), att_conf_id;

-- Short attributes
CREATE VIEW cagg_scalar_devshort_1min(
		att_conf_id, data_time, count_rows, count_errors
		, count_r, mean_r, min_r, max_r, stddev_r
		, count_w, mean_w, min_w, max_w, stddev_w
	) WITH (timescaledb.continuous, timescaledb.refresh_lag = '0 days', timescaledb.refresh_interval='1 min')
       	AS SELECT att_conf_id, time_bucket('1 min', data_time), count(*), count(att_error_desc_id)
		, count(value_r), avg(value_r), min(value_r), max(value_r), stddev(value_r)
		, count(value_w), avg(value_w), min(value_w), max(value_w), stddev(value_w)
       	FROM att_scalar_devshort 
                WHERE data_time > now() - interval '1 year' 
        GROUP BY time_bucket('1 min', data_time), att_conf_id;

CREATE VIEW cagg_scalar_devshort_10min(
		att_conf_id, data_time, count_rows, count_errors
		, count_r, mean_r, min_r, max_r, stddev_r
		, count_w, mean_w, min_w, max_w, stddev_w
	) WITH (timescaledb.continuous, timescaledb.refresh_lag = '0 days', timescaledb.refresh_interval='10 mins')
       	AS SELECT att_conf_id, time_bucket('10 mins', data_time), count(*), count(att_error_desc_id)
		, count(value_r), avg(value_r), min(value_r), max(value_r), stddev(value_r)
		, count(value_w), avg(value_w), min(value_w), max(value_w), stddev(value_w)
       	FROM att_scalar_devshort 
                WHERE data_time > now() - interval '1 year' 
        GROUP BY time_bucket('10 mins', data_time), att_conf_id;

CREATE VIEW cagg_scalar_devshort_1hour(
		att_conf_id, data_time, count_rows, count_errors
		, count_r, mean_r, min_r, max_r, stddev_r
		, count_w, mean_w, min_w, max_w, stddev_w
	) WITH (timescaledb.continuous, timescaledb.refresh_lag = '0 days', timescaledb.refresh_interval='1 hour')
       	AS SELECT att_conf_id, time_bucket('1 hour', data_time), count(*), count(att_error_desc_id)
		, count(value_r), avg(value_r), min(value_r), max(value_r), stddev(value_r)
		, count(value_w), avg(value_w), min(value_w), max(value_w), stddev(value_w)
       	FROM att_scalar_devshort 
                WHERE data_time > now() - interval '1 year' 
        GROUP BY time_bucket('1 hour', data_time), att_conf_id;

CREATE VIEW cagg_scalar_devshort_8hour(
		att_conf_id, data_time, count_rows, count_errors
		, count_r, mean_r, min_r, max_r, stddev_r
		, count_w, mean_w, min_w, max_w, stddev_w
	) WITH (timescaledb.continuous, timescaledb.refresh_lag = '0 days', timescaledb.refresh_interval='8 hours')
       	AS SELECT att_conf_id, time_bucket('8 hours', data_time), count(*), count(att_error_desc_id)
		, count(value_r), avg(value_r), min(value_r), max(value_r), stddev(value_r)
		, count(value_w), avg(value_w), min(value_w), max(value_w), stddev(value_w)
       	FROM att_scalar_devshort 
                WHERE data_time > now() - interval '1 year' 
        GROUP BY time_bucket('8 hours', data_time), att_conf_id;

CREATE VIEW cagg_scalar_devshort_1day(
		att_conf_id, data_time, count_rows, count_errors
		, count_r, mean_r, min_r, max_r, stddev_r
		, count_w, mean_w, min_w, max_w, stddev_w
	) WITH (timescaledb.continuous, timescaledb.refresh_lag = '0 days', timescaledb.refresh_interval='1 day')
       	AS SELECT att_conf_id, time_bucket('1 day', data_time), count(*), count(att_error_desc_id)
		, count(value_r), avg(value_r), min(value_r), max(value_r), stddev(value_r)
		, count(value_w), avg(value_w), min(value_w), max(value_w), stddev(value_w)
       	FROM att_scalar_devshort 
                WHERE data_time > now() - interval '1 year' 
        GROUP BY time_bucket('1 day', data_time), att_conf_id;

-- Unsigned long attributes
CREATE VIEW cagg_scalar_devulong_1min(
		att_conf_id, data_time, count_rows, count_errors
		, count_r, mean_r, min_r, max_r, stddev_r
		, count_w, mean_w, min_w, max_w, stddev_w
	) WITH (timescaledb.continuous, timescaledb.refresh_lag = '0 days', timescaledb.refresh_interval='1 min')
       	AS SELECT att_conf_id, time_bucket('1 min', data_time), count(*), count(att_error_desc_id)
		, count(value_r), avg(value_r), min(value_r), max(value_r), stddev(value_r)
		, count(value_w), avg(value_w), min(value_w), max(value_w), stddev(value_w)
       	FROM att_scalar_devulong 
                WHERE data_time > now() - interval '1 year' 
        GROUP BY time_bucket('1 min', data_time), att_conf_id;

CREATE VIEW cagg_scalar_devulong_10min(
		att_conf_id, data_time, count_rows, count_errors
		, count_r, mean_r, min_r, max_r, stddev_r
		, count_w, mean_w, min_w, max_w, stddev_w
	) WITH (timescaledb.continuous, timescaledb.refresh_lag = '0 days', timescaledb.refresh_interval='10 mins')
       	AS SELECT att_conf_id, time_bucket('10 mins', data_time), count(*), count(att_error_desc_id)
		, count(value_r), avg(value_r), min(value_r), max(value_r), stddev(value_r)
		, count(value_w), avg(value_w), min(value_w), max(value_w), stddev(value_w)
       	FROM att_scalar_devulong 
                WHERE data_time > now() - interval '1 year' 
        GROUP BY time_bucket('10 mins', data_time), att_conf_id;

CREATE VIEW cagg_scalar_devulong_1hour(
		att_conf_id, data_time, count_rows, count_errors
		, count_r, mean_r, min_r, max_r, stddev_r
		, count_w, mean_w, min_w, max_w, stddev_w
	) WITH (timescaledb.continuous, timescaledb.refresh_lag = '0 days', timescaledb.refresh_interval='1 hour')
       	AS SELECT att_conf_id, time_bucket('1 hour', data_time), count(*), count(att_error_desc_id)
		, count(value_r), avg(value_r), min(value_r), max(value_r), stddev(value_r)
		, count(value_w), avg(value_w), min(value_w), max(value_w), stddev(value_w)
       	FROM att_scalar_devulong 
                WHERE data_time > now() - interval '1 year' 
        GROUP BY time_bucket('1 hour', data_time), att_conf_id;

CREATE VIEW cagg_scalar_devulong_8hour(
		att_conf_id, data_time, count_rows, count_errors
		, count_r, mean_r, min_r, max_r, stddev_r
		, count_w, mean_w, min_w, max_w, stddev_w
	) WITH (timescaledb.continuous, timescaledb.refresh_lag = '0 days', timescaledb.refresh_interval='8 hours')
       	AS SELECT att_conf_id, time_bucket('8 hours', data_time), count(*), count(att_error_desc_id)
		, count(value_r), avg(value_r), min(value_r), max(value_r), stddev(value_r)
		, count(value_w), avg(value_w), min(value_w), max(value_w), stddev(value_w)
       	FROM att_scalar_devulong 
                WHERE data_time > now() - interval '1 year' 
        GROUP BY time_bucket('8 hours', data_time), att_conf_id;

CREATE VIEW cagg_scalar_devulong_1day(
		att_conf_id, data_time, count_rows, count_errors
		, count_r, mean_r, min_r, max_r, stddev_r
		, count_w, mean_w, min_w, max_w, stddev_w
	) WITH (timescaledb.continuous, timescaledb.refresh_lag = '0 days', timescaledb.refresh_interval='1 day')
       	AS SELECT att_conf_id, time_bucket('1 day', data_time), count(*), count(att_error_desc_id)
		, count(value_r), avg(value_r), min(value_r), max(value_r), stddev(value_r)
		, count(value_w), avg(value_w), min(value_w), max(value_w), stddev(value_w)
       	FROM att_scalar_devulong 
                WHERE data_time > now() - interval '1 year' 
        GROUP BY time_bucket('1 day', data_time), att_conf_id;

-- Unsigned long 64 attributes
CREATE VIEW cagg_scalar_devulong64_1min(
		att_conf_id, data_time, count_rows, count_errors
		, count_r, mean_r, min_r, max_r, stddev_r
		, count_w, mean_w, min_w, max_w, stddev_w
	) WITH (timescaledb.continuous, timescaledb.refresh_lag = '0 days', timescaledb.refresh_interval='1 min')
       	AS SELECT att_conf_id, time_bucket('1 min', data_time), count(*), count(att_error_desc_id)
		, count(value_r), avg(value_r), min(value_r), max(value_r), stddev(value_r)
		, count(value_w), avg(value_w), min(value_w), max(value_w), stddev(value_w)
       	FROM att_scalar_devulong64 
                WHERE data_time > now() - interval '1 year' 
        GROUP BY time_bucket('1 min', data_time), att_conf_id;

CREATE VIEW cagg_scalar_devulong64_10min(
		att_conf_id, data_time, count_rows, count_errors
		, count_r, mean_r, min_r, max_r, stddev_r
		, count_w, mean_w, min_w, max_w, stddev_w
	) WITH (timescaledb.continuous, timescaledb.refresh_lag = '0 days', timescaledb.refresh_interval='10 mins')
       	AS SELECT att_conf_id, time_bucket('10 mins', data_time), count(*), count(att_error_desc_id)
		, count(value_r), avg(value_r), min(value_r), max(value_r), stddev(value_r)
		, count(value_w), avg(value_w), min(value_w), max(value_w), stddev(value_w)
       	FROM att_scalar_devulong64 
                WHERE data_time > now() - interval '1 year' 
        GROUP BY time_bucket('10 mins', data_time), att_conf_id;

CREATE VIEW cagg_scalar_devulong64_1hour(
		att_conf_id, data_time, count_rows, count_errors
		, count_r, mean_r, min_r, max_r, stddev_r
		, count_w, mean_w, min_w, max_w, stddev_w
	) WITH (timescaledb.continuous, timescaledb.refresh_lag = '0 days', timescaledb.refresh_interval='1 hour')
       	AS SELECT att_conf_id, time_bucket('1 hour', data_time), count(*), count(att_error_desc_id)
		, count(value_r), avg(value_r), min(value_r), max(value_r), stddev(value_r)
		, count(value_w), avg(value_w), min(value_w), max(value_w), stddev(value_w)
       	FROM att_scalar_devulong64 
                WHERE data_time > now() - interval '1 year' 
        GROUP BY time_bucket('1 hour', data_time), att_conf_id;

CREATE VIEW cagg_scalar_devulong64_8hour(
		att_conf_id, data_time, count_rows, count_errors
		, count_r, mean_r, min_r, max_r, stddev_r
		, count_w, mean_w, min_w, max_w, stddev_w
	) WITH (timescaledb.continuous, timescaledb.refresh_lag = '0 days', timescaledb.refresh_interval='8 hours')
       	AS SELECT att_conf_id, time_bucket('8 hours', data_time), count(*), count(att_error_desc_id)
		, count(value_r), avg(value_r), min(value_r), max(value_r), stddev(value_r)
		, count(value_w), avg(value_w), min(value_w), max(value_w), stddev(value_w)
       	FROM att_scalar_devulong64 
                WHERE data_time > now() - interval '1 year' 
        GROUP BY time_bucket('8 hours', data_time), att_conf_id;

CREATE VIEW cagg_scalar_devulong64_1day(
		att_conf_id, data_time, count_rows, count_errors
		, count_r, mean_r, min_r, max_r, stddev_r
		, count_w, mean_w, min_w, max_w, stddev_w
	) WITH (timescaledb.continuous, timescaledb.refresh_lag = '0 days', timescaledb.refresh_interval='1 day')
       	AS SELECT att_conf_id, time_bucket('1 day', data_time), count(*), count(att_error_desc_id)
		, count(value_r), avg(value_r), min(value_r), max(value_r), stddev(value_r)
		, count(value_w), avg(value_w), min(value_w), max(value_w), stddev(value_w)
       	FROM att_scalar_devulong64 
                WHERE data_time > now() - interval '1 year' 
        GROUP BY time_bucket('1 day', data_time), att_conf_id;

-- Unsigned short attributes
CREATE VIEW cagg_scalar_devushort_1min(
		att_conf_id, data_time, count_rows, count_errors
		, count_r, mean_r, min_r, max_r, stddev_r
		, count_w, mean_w, min_w, max_w, stddev_w
	) WITH (timescaledb.continuous, timescaledb.refresh_lag = '0 days', timescaledb.refresh_interval='1 min')
       	AS SELECT att_conf_id, time_bucket('1 min', data_time), count(*), count(att_error_desc_id)
		, count(value_r), avg(value_r), min(value_r), max(value_r), stddev(value_r)
		, count(value_w), avg(value_w), min(value_w), max(value_w), stddev(value_w)
       	FROM att_scalar_devushort 
                WHERE data_time > now() - interval '1 year' 
        GROUP BY time_bucket('1 min', data_time), att_conf_id;

CREATE VIEW cagg_scalar_devushort_10min(
		att_conf_id, data_time, count_rows, count_errors
		, count_r, mean_r, min_r, max_r, stddev_r
		, count_w, mean_w, min_w, max_w, stddev_w
	) WITH (timescaledb.continuous, timescaledb.refresh_lag = '0 days', timescaledb.refresh_interval='10 mins')
       	AS SELECT att_conf_id, time_bucket('10 mins', data_time), count(*), count(att_error_desc_id)
		, count(value_r), avg(value_r), min(value_r), max(value_r), stddev(value_r)
		, count(value_w), avg(value_w), min(value_w), max(value_w), stddev(value_w)
       	FROM att_scalar_devushort 
                WHERE data_time > now() - interval '1 year' 
        GROUP BY time_bucket('10 mins', data_time), att_conf_id;

CREATE VIEW cagg_scalar_devushort_1hour(
		att_conf_id, data_time, count_rows, count_errors
		, count_r, mean_r, min_r, max_r, stddev_r
		, count_w, mean_w, min_w, max_w, stddev_w
	) WITH (timescaledb.continuous, timescaledb.refresh_lag = '0 days', timescaledb.refresh_interval='1 hour')
       	AS SELECT att_conf_id, time_bucket('1 hour', data_time), count(*), count(att_error_desc_id)
		, count(value_r), avg(value_r), min(value_r), max(value_r), stddev(value_r)
		, count(value_w), avg(value_w), min(value_w), max(value_w), stddev(value_w)
       	FROM att_scalar_devushort 
                WHERE data_time > now() - interval '1 year' 
        GROUP BY time_bucket('1 hour', data_time), att_conf_id;

CREATE VIEW cagg_scalar_devushort_8hour(
		att_conf_id, data_time, count_rows, count_errors
		, count_r, mean_r, min_r, max_r, stddev_r
		, count_w, mean_w, min_w, max_w, stddev_w
	) WITH (timescaledb.continuous, timescaledb.refresh_lag = '0 days', timescaledb.refresh_interval='8 hours')
       	AS SELECT att_conf_id, time_bucket('8 hours', data_time), count(*), count(att_error_desc_id)
		, count(value_r), avg(value_r), min(value_r), max(value_r), stddev(value_r)
		, count(value_w), avg(value_w), min(value_w), max(value_w), stddev(value_w)
       	FROM att_scalar_devushort 
                WHERE data_time > now() - interval '1 year' 
        GROUP BY time_bucket('8 hours', data_time), att_conf_id;

CREATE VIEW cagg_scalar_devushort_1day(
		att_conf_id, data_time, count_rows, count_errors
		, count_r, mean_r, min_r, max_r, stddev_r
		, count_w, mean_w, min_w, max_w, stddev_w
	) WITH (timescaledb.continuous, timescaledb.refresh_lag = '0 days', timescaledb.refresh_interval='1 day')
       	AS SELECT att_conf_id, time_bucket('1 day', data_time), count(*), count(att_error_desc_id)
		, count(value_r), avg(value_r), min(value_r), max(value_r), stddev(value_r)
		, count(value_w), avg(value_w), min(value_w), max(value_w), stddev(value_w)
       	FROM att_scalar_devushort 
                WHERE data_time > now() - interval '1 year' 
        GROUP BY time_bucket('1 day', data_time), att_conf_id;

-- Drop all the views
-- DROP VIEW cagg_scalar_devdouble_1min CASCADE;
-- DROP VIEW cagg_scalar_devdouble_10min CASCADE;
-- DROP VIEW cagg_scalar_devdouble_1hour CASCADE;
-- DROP VIEW cagg_scalar_devdouble_8hour CASCADE;
-- DROP VIEW cagg_scalar_devdouble_1day CASCADE;

-- DROP VIEW cagg_scalar_devfloat_1min CASCADE;
-- DROP VIEW cagg_scalar_devfloat_10min CASCADE;
-- DROP VIEW cagg_scalar_devfloat_1hour CASCADE;
-- DROP VIEW cagg_scalar_devfloat_8hour CASCADE;
-- DROP VIEW cagg_scalar_devfloat_1day CASCADE;

-- DROP VIEW cagg_scalar_devlong_1min CASCADE;
-- DROP VIEW cagg_scalar_devlong_10min CASCADE;
-- DROP VIEW cagg_scalar_devlong_1hour CASCADE;
-- DROP VIEW cagg_scalar_devlong_8hour CASCADE;
-- DROP VIEW cagg_scalar_devlong_1day CASCADE;

-- DROP VIEW cagg_scalar_devlong64_1min CASCADE;
-- DROP VIEW cagg_scalar_devlong64_10min CASCADE;
-- DROP VIEW cagg_scalar_devlong64_1hour CASCADE;
-- DROP VIEW cagg_scalar_devlong64_8hour CASCADE;
-- DROP VIEW cagg_scalar_devlong64_1day CASCADE;

-- DROP VIEW cagg_scalar_devshort_1min CASCADE;
-- DROP VIEW cagg_scalar_devshort_10min CASCADE;
-- DROP VIEW cagg_scalar_devshort_1hour CASCADE;
-- DROP VIEW cagg_scalar_devshort_8hour CASCADE;
-- DROP VIEW cagg_scalar_devshort_1day CASCADE;

-- DROP VIEW cagg_scalar_devulong_1min CASCADE;
-- DROP VIEW cagg_scalar_devulong_10min CASCADE;
-- DROP VIEW cagg_scalar_devulong_1hour CASCADE;
-- DROP VIEW cagg_scalar_devulong_8hour CASCADE;
-- DROP VIEW cagg_scalar_devulong_1day CASCADE;

-- DROP VIEW cagg_scalar_devulong64_1min CASCADE;
-- DROP VIEW cagg_scalar_devulong64_10min CASCADE;
-- DROP VIEW cagg_scalar_devulong64_1hour CASCADE;
-- DROP VIEW cagg_scalar_devulong64_8hour CASCADE;
-- DROP VIEW cagg_scalar_devulong64_1day CASCADE;

-- DROP VIEW cagg_scalar_devushort_1min CASCADE;
-- DROP VIEW cagg_scalar_devushort_10min CASCADE;
-- DROP VIEW cagg_scalar_devushort_1hour CASCADE;
-- DROP VIEW cagg_scalar_devushort_8hour CASCADE;
-- DROP VIEW cagg_scalar_devushort_1day CASCADE;

