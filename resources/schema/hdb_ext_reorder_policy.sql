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
-- Reorder chunk policy

SELECT add_reorder_policy('att_scalar_devboolean', 'att_scalar_devboolean_att_conf_id_data_time_idx', if_not_exists => true);
SELECT add_reorder_policy('att_scalar_devdouble', 'att_scalar_devdouble_att_conf_id_data_time_idx', if_not_exists => true);
SELECT add_reorder_policy('att_scalar_devfloat', 'att_scalar_devfloat_att_conf_id_data_time_idx', if_not_exists => true);
SELECT add_reorder_policy('att_scalar_devencoded', 'att_scalar_devencoded_att_conf_id_data_time_idx', if_not_exists => true);
SELECT add_reorder_policy('att_scalar_devenum', 'att_scalar_devenum_att_conf_id_data_time_idx', if_not_exists => true);
SELECT add_reorder_policy('att_scalar_devstate', 'att_scalar_devstate_att_conf_id_data_time_idx', if_not_exists => true);
SELECT add_reorder_policy('att_scalar_devstring', 'att_scalar_devstring_att_conf_id_data_time_idx', if_not_exists => true);
SELECT add_reorder_policy('att_scalar_devuchar', 'att_scalar_devuchar_att_conf_id_data_time_idx', if_not_exists => true);
SELECT add_reorder_policy('att_scalar_devulong', 'att_scalar_devulong_att_conf_id_data_time_idx', if_not_exists => true);
SELECT add_reorder_policy('att_scalar_devulong64', 'att_scalar_devulong64_att_conf_id_data_time_idx', if_not_exists => true);
SELECT add_reorder_policy('att_scalar_devlong64', 'att_scalar_devlong64_att_conf_id_data_time_idx', if_not_exists => true);
SELECT add_reorder_policy('att_scalar_devlong', 'att_scalar_devlong_att_conf_id_data_time_idx', if_not_exists => true);
SELECT add_reorder_policy('att_scalar_devushort', 'att_scalar_devushort_att_conf_id_data_time_idx', if_not_exists => true);
SELECT add_reorder_policy('att_scalar_devshort', 'att_scalar_devshort_att_conf_id_data_time_idx', if_not_exists => true);

SELECT add_reorder_policy('att_array_devboolean', 'att_array_devboolean_att_conf_id_data_time_idx', if_not_exists => true);
SELECT add_reorder_policy('att_array_devdouble', 'att_array_devdouble_att_conf_id_data_time_idx', if_not_exists => true);
SELECT add_reorder_policy('att_array_devfloat', 'att_array_devfloat_att_conf_id_data_time_idx', if_not_exists => true);
SELECT add_reorder_policy('att_array_devencoded', 'att_array_devencoded_att_conf_id_data_time_idx', if_not_exists => true);
SELECT add_reorder_policy('att_array_devenum', 'att_array_devenum_att_conf_id_data_time_idx', if_not_exists => true);
SELECT add_reorder_policy('att_array_devstate', 'att_array_devstate_att_conf_id_data_time_idx', if_not_exists => true);
SELECT add_reorder_policy('att_array_devstring', 'att_array_devstring_att_conf_id_data_time_idx', if_not_exists => true);
SELECT add_reorder_policy('att_array_devuchar', 'att_array_devuchar_att_conf_id_data_time_idx', if_not_exists => true);
SELECT add_reorder_policy('att_array_devulong', 'att_array_devulong_att_conf_id_data_time_idx', if_not_exists => true);
SELECT add_reorder_policy('att_array_devulong64', 'att_array_devulong64_att_conf_id_data_time_idx', if_not_exists => true);
SELECT add_reorder_policy('att_array_devlong64', 'att_array_devlong64_att_conf_id_data_time_idx', if_not_exists => true);
SELECT add_reorder_policy('att_array_devlong', 'att_array_devlong_att_conf_id_data_time_idx', if_not_exists => true);
SELECT add_reorder_policy('att_array_devushort', 'att_array_devushort_att_conf_id_data_time_idx', if_not_exists => true);
SELECT add_reorder_policy('att_array_devshort', 'att_array_devshort_att_conf_id_data_time_idx', if_not_exists => true);
