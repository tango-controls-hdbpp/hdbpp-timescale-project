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
CREATE TABLE IF NOT EXISTS postprocessing_conf (
    postprocessing_conf_id bigint GENERATED ALWAYS AS IDENTITY
                 PRIMARY KEY,
    att_conf_id integer,
    custom_selection text,
    priority integer NOT NULL DEFAULT 0,
    pp_function text NOT NULL,
    pp_parameters jsonb,
    CONSTRAINT selection_notnull CHECK (
        NOT ( att_conf_id IS NULL  AND  custom_selection IS NULL )
    )
);

COMMENT ON TABLE postprocessing_conf is 'Data postprocessing configuration';

-- The postprocessing_jobs table contains information on postprocessing jobs.
-- The postprocessing_job_id can then be used to retrieve more precise information on the job
CREATE TABLE IF NOT EXISTS postprocessing_jobs (
    postprocessing_job_id bigint GENERATED ALWAYS AS IDENTITY
                 PRIMARY KEY,
    postprocessing_conf_id bigint NOT NULL,
    start_time timestamptz NOT NULL,
    duration interval,
    error_desc text,
    FOREIGN KEY (postprocessing_conf_id) REFERENCES postprocessing_conf (postprocessing_conf_id)
);

COMMENT ON TABLE postprocessing_jobs is 'Data postprocessing jobs';
