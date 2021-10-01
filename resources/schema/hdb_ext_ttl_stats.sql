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

-- The ttl_jobs table contains information on ttl jobs.
-- The ttl_job_id can then be used to retrieve more precise information on the job
CREATE TABLE IF NOT EXISTS ttl_jobs (
    ttl_job_id bigint GENERATED ALWAYS AS IDENTITY
                 PRIMARY KEY,
    start_time timestamptz NOT NULL,
    duration interval,
    error_desc text
);

COMMENT ON TABLE ttl_jobs is 'Attributes TTL removal jobs';

CREATE TABLE IF NOT EXISTS ttl_stats (
    ttl_job_id bigint NOT NULL,
    att_conf_id integer NOT NULL,
    deleted_rows bigint NOT NULL,
    duration interval,
    error_desc text,
    PRIMARY KEY (att_conf_id, ttl_job_id),
    FOREIGN KEY (att_conf_id) REFERENCES att_conf (att_conf_id),
    FOREIGN KEY (ttl_job_id) REFERENCES ttl_jobs (ttl_job_id)
);

COMMENT ON TABLE ttl_stats is 'Per attribute TTL removal job statistics';
