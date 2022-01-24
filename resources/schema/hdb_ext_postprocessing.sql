-- -----------------------------------------------------------------------------
-- This file is part of the hdbpp-timescale-project
--
-- Copyright (C) : 2014-2022
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

-- The postprocessing_jobs table contains information on postprocessing jobs.
-- The postprocessing_job_id can then be used to retrieve more precise information on the job
CREATE TABLE IF NOT EXISTS postprocessing_jobs (
    job_id bigint GENERATED ALWAYS AS IDENTITY
                 PRIMARY KEY,
    application_name text,
    proc_name text,
    config jsonb
);

COMMENT ON TABLE postprocessing_jobs is 'Postprocessing jobs table';

-- The postprocessing_jobs table contains information on postprocessing jobs.
-- The postprocessing_job_id can then be used to retrieve more precise information on the job
CREATE TABLE IF NOT EXISTS postprocessing_jobs_stats (
    job_id bigint PRIMARY KEY REFERENCES postprocessing_jobs,
    last_run_started_at timestamptz,
    last_successful_finish timestamptz,
    last_run_status text,
    job_status text,
    last_run_duration interval,
    total_runs bigint,
    total_successes bigint,
    total_failures bigint
);

COMMENT ON TABLE postprocessing_jobs_stats is 'Data postprocessing jobs stats';
