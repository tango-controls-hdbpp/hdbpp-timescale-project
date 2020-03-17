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

-- Aggregates function helper for the continuous aggregates views for the array attributes.

/*
NOT USED
Keep as a different approach, should be benchmarked for execution speed

-- Special type to be used as input by compute_element_agg
-- It contains past aggregates result and the new values
create type double_agg_input as (
    value_r double precision,
    value_w double precision,
    count_r integer,
    count_nan_r integer,
    avg_r double precision,
    min_r double precision,
    max_r double precision,
    stddev_r double precision,
    count_w integer,
    count_nan_w integer,
    avg_w double precision,
    min_w double precision,
    max_w double precision,
    stddev_w double precision
);

-- Function to compute the aggregates from the new values and old aggregates
-- result.
-- It computes the result for an array of input and return a table so that it 
-- can be used in a FROM clause
CREATE OR REPLACE FUNCTION compute_element_agg(inp_arr double_agg_input[]
    ) RETURNS SETOF RECORD as $$

DECLARE
    ret RECORD;
    inp double_agg_input;
    value_r double precision;
    value_w double precision;
    count_r integer;
    count_nan_r integer;
    avg_r double precision;
    min_r double precision;
    max_r double precision;
    stddev_r double precision;
    count_w integer;
    count_nan_w integer;
    avg_w double precision;
    min_w double precision;
    max_w double precision;
    stddev_w double precision;
    n_count_r integer;
    n_count_nan_r integer;
    n_avg_r double precision;
    n_min_r double precision;
    n_max_r double precision;
    n_stddev_r double precision;
    n_count_w integer;
    n_count_nan_w integer;
    n_avg_w double precision;
    n_min_w double precision;
    n_max_w double precision;
    n_stddev_w double precision;

BEGIN
    FOREACH inp IN ARRAY inp_arr
    LOOP

        value_r := inp.value_r;
        value_w := inp.value_w;
        count_r :=  inp.count_r;
        count_nan_r := inp.count_nan_r;
        avg_r := inp.avg_r;
        min_r := inp.min_r;
        max_r := inp.max_r;
        stddev_r := inp.stddev_r;
        count_w := inp.count_w;
        count_nan_w := inp.count_nan_w;
        avg_w := inp.avg_w;
        min_w := inp.min_w;
        stddev_w := inp.stddev_w;
        
        IF value_r IS NULL OR value_r='NaN'::float8 OR value_r='Infinity' OR value_r='-Infinity'
        THEN
                
            IF count_r IS NULL
            THEN
                n_count_r = 0;
            ELSE
                n_count_r = count_r;
            END IF;
        
            IF value_r IS NULL
            THEN
                
                IF count_nan_r IS NULL
                THEN
                    n_count_nan_r = 0;
                ELSE
                    n_count_nan_r = count_nan_r;
                END IF;
        
            ELSE
                
                IF count_nan_r IS NULL
                THEN
                    n_count_nan_r = 1;
                ELSE
                    n_count_nan_r = count_nan_r + 1;
                END IF;
            END IF;
        
            n_avg_r = avg_r;
            n_min_r = min_r;
            n_max_r = max_r;
            n_stddev_r = stddev_r;
    
        ELSE
        
            IF count_nan_r IS NULL
            THEN
                n_count_nan_r = 0;
            ELSE
                n_count_nan_r = count_nan_r;
            END IF;

            IF count_r IS NULL
            THEN
                n_count_r = 1;
            ELSE
                n_count_r = count_r + 1;
            END IF;
            
            IF avg_r IS NULL
            THEN
                n_avg_r = value_r;
            ELSE
                n_avg_r = avg_r + (value_r-avg_r)/(count_r+1.);
            END IF;
        
            n_min_r = LEAST(value_r, min_r);
            n_max_r = GREATEST(value_r, max_r);
        
            IF stddev_r IS NULL
            THEN
                n_stddev_r = 0;
            ELSE
                n_stddev_r = stddev_r + ((count_r + 0.)/(count_r+1.))*power(value_r - avg_r, 2);
            END IF;
        END IF;
    
        IF value_w IS NULL OR value_w='NaN'::float8 OR value_w='Infinity' OR value_w='-Infinity'
        THEN
        
            IF count_w IS NULL
            THEN
                n_count_w = 0;
            ELSE
                n_count_w = count_w;
            END IF;
        
            IF value_w IS NULL
            THEN
            
                IF count_nan_w IS NULL
                THEN
                    n_count_nan_w = 0;
                ELSE
                    n_count_nan_w = count_nan_w;
                END IF;
        
            ELSE
            
                IF count_nan_w IS NULL
                THEN
                    n_count_nan_w = 1;
                ELSE
                    n_count_nan_w = count_nan_w + 1;
                END IF;
            END IF;
        
            n_avg_w = avg_w;
            n_min_w = min_w;
            n_max_w = max_w;
            n_stddev_w = stddev_w;
        
        ELSE
        
            IF count_nan_w IS NULL
            THEN
                n_count_nan_w = 0;
            ELSE
                n_count_nan_w = count_nan_w;
            END IF;
        
            IF count_w IS NULL
            THEN
                n_count_w = 1;
            ELSE
                n_count_w = count_w + 1;
            END IF;
        
            IF avg_w IS NULL
            THEN
                n_avg_w = value_w;
            ELSE
                n_avg_w = avg_w + (value_w-avg_w)/(count_w+1);
            END IF;
        
            n_min_w = LEAST(value_w, min_w);
            n_max_w = GREATEST(value_w, max_w);
        
            IF stddev_w IS NULL
            THEN
                n_stddev_w = 0;
            ELSE
                n_stddev_w = stddev_w + ((count_w + 0.)/(count_w+1.)*power(value_w - avg_w, 2));
            END IF;
        END IF;

        ret := (n_count_r, n_count_nan_r, n_avg_r, n_min_r, n_max_r, n_stddev_r
            , n_count_w, n_count_nan_w, n_avg_w, n_min_w, n_max_w, n_stddev_w);

        return next ret;
    END LOOP;
END;
$$
LANGUAGE 'plpgsql';
*/


-- Special types to store the aggregations data during computation
create type double_array_agg_state as (
	count integer,
	count_errors integer,
        count_r integer[],
        count_nan_r integer[],
	avg_r double precision[],
        min_r double precision[],
        max_r double precision[],
	stddev_r double precision[],
        count_w integer[],
        count_nan_w integer[],
	avg_w double precision[],
        min_w double precision[],
        max_w double precision[],
	stddev_w double precision[]
);

create type float_array_agg_state as (
	count integer,
	count_errors integer,
        count_r integer[],
        count_nan_r integer[],
	avg_r double precision[],
        min_r real[],
        max_r real[],
	stddev_r double precision[],
        count_w integer[],
        count_nan_w integer[],
	avg_w double precision[],
        min_w real[],
        max_w real[],
	stddev_w double precision[]
);

create type long_array_agg_state as (
	count integer,
	count_errors integer,
        count_r integer[],
	avg_r double precision[],
        min_r integer[],
        max_r integer[],
	stddev_r double precision[],
        count_w integer[],
	avg_w double precision[],
        min_w integer[],
        max_w integer[],
	stddev_w double precision[]
);

create type long64_array_agg_state as (
	count integer,
	count_errors integer,
        count_r integer[],
	avg_r double precision[],
        min_r bigint[],
        max_r bigint[],
	stddev_r double precision[],
        count_w integer[],
	avg_w double precision[],
        min_w bigint[],
        max_w bigint[],
	stddev_w double precision[]
);

create type short_array_agg_state as (
	count integer,
	count_errors integer,
        count_r integer[],
	avg_r double precision[],
        min_r smallint[],
        max_r smallint[],
	stddev_r double precision[],
        count_w integer[],
	avg_w double precision[],
        min_w smallint[],
        max_w smallint[],
	stddev_w double precision[]
);

create type ulong_array_agg_state as (
	count integer,
	count_errors integer,
        count_r integer[],
	avg_r double precision[],
        min_r ulong[],
        max_r ulong[],
	stddev_r double precision[],
        count_w integer[],
	avg_w double precision[],
        min_w ulong[],
        max_w ulong[],
	stddev_w double precision[]
);

create type ulong64_array_agg_state as (
	count integer,
	count_errors integer,
        count_r integer[],
	avg_r double precision[],
        min_r ulong64[],
        max_r ulong64[],
	stddev_r double precision[],
        count_w integer[],
	avg_w double precision[],
        min_w ulong64[],
        max_w ulong64[],
	stddev_w double precision[]
);

create type ushort_array_agg_state as (
	count integer,
	count_errors integer,
        count_r integer[],
	avg_r double precision[],
        min_r ushort[],
        max_r ushort[],
	stddev_r double precision[],
        count_w integer[],
	avg_w double precision[],
        min_w ushort[],
        max_w ushort[],
	stddev_w double precision[]
);

-- Function to combine to aggregate state into a new one
-- needed for the aggregate function to be used for partial aggregation
CREATE OR REPLACE FUNCTION fn_double_combine(double_array_agg_state, double_array_agg_state)
    RETURNS double_array_agg_state AS $$

DECLARE
    state1 ALIAS FOR $1;
    state2 ALIAS FOR $2;
    count integer;
    count_errors integer;
    result double_array_agg_state%ROWTYPE;

BEGIN

    -- Limit cases. 
    IF state1 is NULL
    THEN
        return state2;
    END IF;
    
    IF state2 is NULL
    THEN
        return state1;
    END IF;

    -- if there is a discrepancy in the arrays sizes
    IF CARDINALITY(state1.avg_r) != CARDINALITY(state2.avg_r) OR CARDINALITY(state1.avg_w) != CARDINALITY(state2.avg_w) THEN
        SELECT 0, 0,
        ARRAY[]::integer[], ARRAY[]::integer[], ARRAY[]::float8[], ARRAY[]::float8[], ARRAY[]::float8[], ARRAY[]::float8[],
        ARRAY[]::integer[], ARRAY[]::integer[], ARRAY[]::float8[], ARRAY[]::float8[], ARRAY[]::float8[], ARRAY[]::float8[]
        INTO result;
    ELSE
	
    count := state1.count + state2.count;
    count_errors := state1.count_errors + state2.count_errors;
    
    WITH arrays AS(
        SELECT 
            UNNEST(state1.count_r) AS count_r1, UNNEST(state1.count_nan_r) AS nan_r1, UNNEST(state1.avg_r) AS avg_r1,
            UNNEST(state1.min_r) AS min_r1, UNNEST(state1.max_r) AS max_r1, UNNEST(state1.stddev_r) AS stddev_r1,
            UNNEST(state1.count_w) AS count_w1, UNNEST(state1.count_nan_w) AS nan_w1, UNNEST(state1.avg_w) AS avg_w1,
            UNNEST(state1.min_w) AS min_w1, UNNEST(state1.max_w) AS max_w1, UNNEST(state1.stddev_w) AS stddev_w1,
            UNNEST(state2.count_r) AS count_r2, UNNEST(state2.count_nan_r) AS nan_r2, UNNEST(state2.avg_r) AS avg_r2,
            UNNEST(state2.min_r) AS min_r2, UNNEST(state2.max_r) AS max_r2, UNNEST(state2.stddev_r) AS stddev_r2,
            UNNEST(state2.count_w) AS count_w2, UNNEST(state2.count_nan_w) AS nan_w2, UNNEST(state2.avg_w) AS avg_w2,
            UNNEST(state2.min_w) AS min_w2, UNNEST(state2.max_w) AS max_w2, UNNEST(state2.stddev_w) AS stddev_w2
        )
        SELECT count, count_errors,
            array_agg(count_r1+count_r2), array_agg(count_nan_r1+count_nan_r2),
            array_agg(avg_r1 + (count_r2/(count_r1+count_r2))*(avg_r2-avg_r1)), array_agg(LEAST(min_r1, min_r2)), array_agg(GREATEST(max_r1, max_r2)),
            array_agg(stddev_r1 + (count_r2*count_r1/count_r1+count_r2)*power(avg_r2 - avg_r1, 2)),
            array_agg(count_w1+count_w2), array_agg(count_nan_w1+count_nan_w2),
            array_agg(avg_w1 + (count_w2/(count_w1+count_w2))*(avg_w2-avg_w1)), array_agg(LEAST(min_w1, min_w2)), array_agg(GREATEST(max_w1, max_w2)),
            array_agg(stddev_w1 + (count_w2*count_w1/count_w1+count_w2)*power(avg_w2 - avg_w1, 2))
        INTO result FROM arrays;
    END IF;
    
    return result;
END;
$$
LANGUAGE 'plpgsql';

CREATE OR REPLACE FUNCTION fn_float_combine(float_array_agg_state, float_array_agg_state)
    RETURNS float_array_agg_state AS $$

DECLARE
    state1 ALIAS FOR $1;
    state2 ALIAS FOR $2;
    count integer;
    count_errors integer;
    result float_array_agg_state%ROWTYPE;

BEGIN

    -- Limit cases. 
    IF state1 is NULL
    THEN
        return state2;
    END IF;
    
    IF state2 is NULL
    THEN
        return state1;
    END IF;

    -- if there is a discrepancy in the arrays sizes
    IF CARDINALITY(state1.avg_r) != CARDINALITY(state2.avg_r) OR CARDINALITY(state1.avg_w) != CARDINALITY(state2.avg_w) THEN
        SELECT 0, 0,
        ARRAY[]::integer[], ARRAY[]::integer[], ARRAY[]::float8[], ARRAY[]::real[], ARRAY[]::real[], ARRAY[]::float8[],
        ARRAY[]::integer[], ARRAY[]::integer[], ARRAY[]::float8[], ARRAY[]::real[], ARRAY[]::real[], ARRAY[]::float8[]
        INTO result;
    ELSE
	
    count := state1.count + state2.count;
    count_errors := state1.count_errors + state2.count_errors;
    
    WITH arrays AS(
        SELECT 
            UNNEST(state1.count_r) AS count_r1, UNNEST(state1.count_nan_r) AS nan_r1, UNNEST(state1.avg_r) AS avg_r1,
            UNNEST(state1.min_r) AS min_r1, UNNEST(state1.max_r) AS max_r1, UNNEST(state1.stddev_r) AS stddev_r1,
            UNNEST(state1.count_w) AS count_w1, UNNEST(state1.count_nan_w) AS nan_w1, UNNEST(state1.avg_w) AS avg_w1,
            UNNEST(state1.min_w) AS min_w1, UNNEST(state1.max_w) AS max_w1, UNNEST(state1.stddev_w) AS stddev_w1,
            UNNEST(state2.count_r) AS count_r2, UNNEST(state2.count_nan_r) AS nan_r2, UNNEST(state2.avg_r) AS avg_r2,
            UNNEST(state2.min_r) AS min_r2, UNNEST(state2.max_r) AS max_r2, UNNEST(state2.stddev_r) AS stddev_r2,
            UNNEST(state2.count_w) AS count_w2, UNNEST(state2.count_nan_w) AS nan_w2, UNNEST(state2.avg_w) AS avg_w2,
            UNNEST(state2.min_w) AS min_w2, UNNEST(state2.max_w) AS max_w2, UNNEST(state2.stddev_w) AS stddev_w2
        )
        SELECT count, count_errors,
            array_agg(count_r1+count_r2), array_agg(count_nan_r1+count_nan_r2),
            array_agg(avg_r1 + (count_r2/(count_r1+count_r2))*(avg_r2-avg_r1)), array_agg(LEAST(min_r1, min_r2)), array_agg(GREATEST(max_r1, max_r2)),
            array_agg(stddev_r1 + (count_r2*count_r1/count_r1+count_r2)*power(avg_r2 - avg_r1, 2)),
            array_agg(count_w1+count_w2), array_agg(count_nan_w1+count_nan_w2),
            array_agg(avg_w1 + (count_w2/(count_w1+count_w2))*(avg_w2-avg_w1)), array_agg(LEAST(min_w1, min_w2)), array_agg(GREATEST(max_w1, max_w2)),
            array_agg(stddev_w1 + (count_w2*count_w1/count_w1+count_w2)*power(avg_w2 - avg_w1, 2))
        INTO result FROM arrays;
    END IF;
    
    return result;
END;
$$
LANGUAGE 'plpgsql';

CREATE OR REPLACE FUNCTION fn_long_combine(long_array_agg_state, long_array_agg_state)
    RETURNS long_array_agg_state AS $$

DECLARE
    state1 ALIAS FOR $1;
    state2 ALIAS FOR $2;
    count integer;
    count_errors integer;
    result long_array_agg_state%ROWTYPE;

BEGIN

    -- Limit cases. 
    IF state1 is NULL
    THEN
        return state2;
    END IF;
    
    IF state2 is NULL
    THEN
        return state1;
    END IF;

    -- if there is a discrepancy in the arrays sizes
    IF CARDINALITY(state1.avg_r) != CARDINALITY(state2.avg_r) OR CARDINALITY(state1.avg_w) != CARDINALITY(state2.avg_w) THEN
        SELECT 0, 0,
        ARRAY[]::integer[], ARRAY[]::float8[], ARRAY[]::integer[], ARRAY[]::integer[], ARRAY[]::float8[],
        ARRAY[]::integer[], ARRAY[]::float8[], ARRAY[]::integer[], ARRAY[]::integer[], ARRAY[]::float8[]
        INTO result;
    ELSE
	
    count := state1.count + state2.count;
    count_errors := state1.count_errors + state2.count_errors;
    
    WITH arrays AS(
        SELECT 
            UNNEST(state1.count_r) AS count_r1, UNNEST(state1.count_nan_r) AS nan_r1, UNNEST(state1.avg_r) AS avg_r1,
            UNNEST(state1.min_r) AS min_r1, UNNEST(state1.max_r) AS max_r1, UNNEST(state1.stddev_r) AS stddev_r1,
            UNNEST(state1.count_w) AS count_w1, UNNEST(state1.count_nan_w) AS nan_w1, UNNEST(state1.avg_w) AS avg_w1,
            UNNEST(state1.min_w) AS min_w1, UNNEST(state1.max_w) AS max_w1, UNNEST(state1.stddev_w) AS stddev_w1,
            UNNEST(state2.count_r) AS count_r2, UNNEST(state2.count_nan_r) AS nan_r2, UNNEST(state2.avg_r) AS avg_r2,
            UNNEST(state2.min_r) AS min_r2, UNNEST(state2.max_r) AS max_r2, UNNEST(state2.stddev_r) AS stddev_r2,
            UNNEST(state2.count_w) AS count_w2, UNNEST(state2.count_nan_w) AS nan_w2, UNNEST(state2.avg_w) AS avg_w2,
            UNNEST(state2.min_w) AS min_w2, UNNEST(state2.max_w) AS max_w2, UNNEST(state2.stddev_w) AS stddev_w2
        )
        SELECT count, count_errors,
            array_agg(count_r1+count_r2),
            array_agg(avg_r1 + (count_r2/(count_r1+count_r2))*(avg_r2-avg_r1)), array_agg(LEAST(min_r1, min_r2)), array_agg(GREATEST(max_r1, max_r2)),
            array_agg(stddev_r1 + (count_r2*count_r1/count_r1+count_r2)*power(avg_r2 - avg_r1, 2)),
            array_agg(count_w1+count_w2),
            array_agg(avg_w1 + (count_w2/(count_w1+count_w2))*(avg_w2-avg_w1)), array_agg(LEAST(min_w1, min_w2)), array_agg(GREATEST(max_w1, max_w2)),
            array_agg(stddev_w1 + (count_w2*count_w1/count_w1+count_w2)*power(avg_w2 - avg_w1, 2))
        INTO result FROM arrays;
    END IF;
    
    return result;
END;
$$
LANGUAGE 'plpgsql';

CREATE OR REPLACE FUNCTION fn_long64_combine(long64_array_agg_state, long64_array_agg_state)
    RETURNS long64_array_agg_state AS $$

DECLARE
    state1 ALIAS FOR $1;
    state2 ALIAS FOR $2;
    count integer;
    count_errors integer;
    result long64_array_agg_state%ROWTYPE;

BEGIN

    -- Limit cases. 
    IF state1 is NULL
    THEN
        return state2;
    END IF;
    
    IF state2 is NULL
    THEN
        return state1;
    END IF;

    -- if there is a discrepancy in the arrays sizes
    IF CARDINALITY(state1.avg_r) != CARDINALITY(state2.avg_r) OR CARDINALITY(state1.avg_w) != CARDINALITY(state2.avg_w) THEN
        SELECT 0, 0,
        ARRAY[]::integer[], ARRAY[]::float8[], ARRAY[]::bigint[], ARRAY[]::bigint[], ARRAY[]::float8[],
        ARRAY[]::integer[], ARRAY[]::float8[], ARRAY[]::bigint[], ARRAY[]::bigint[], ARRAY[]::float8[]
        INTO result;
    ELSE
	
    count := state1.count + state2.count;
    count_errors := state1.count_errors + state2.count_errors;
    
    WITH arrays AS(
        SELECT 
            UNNEST(state1.count_r) AS count_r1, UNNEST(state1.avg_r) AS avg_r1,
            UNNEST(state1.min_r) AS min_r1, UNNEST(state1.max_r) AS max_r1, UNNEST(state1.stddev_r) AS stddev_r1,
            UNNEST(state1.count_w) AS count_w1, UNNEST(state1.avg_w) AS avg_w1,
            UNNEST(state1.min_w) AS min_w1, UNNEST(state1.max_w) AS max_w1, UNNEST(state1.stddev_w) AS stddev_w1,
            UNNEST(state2.count_r) AS count_r2, UNNEST(state2.avg_r) AS avg_r2,
            UNNEST(state2.min_r) AS min_r2, UNNEST(state2.max_r) AS max_r2, UNNEST(state2.stddev_r) AS stddev_r2,
            UNNEST(state2.count_w) AS count_w2, UNNEST(state2.avg_w) AS avg_w2,
            UNNEST(state2.min_w) AS min_w2, UNNEST(state2.max_w) AS max_w2, UNNEST(state2.stddev_w) AS stddev_w2
        )
        SELECT count, count_errors,
            array_agg(count_r1+count_r2),
            array_agg(avg_r1 + (count_r2/(count_r1+count_r2))*(avg_r2-avg_r1)), array_agg(LEAST(min_r1, min_r2)), array_agg(GREATEST(max_r1, max_r2)),
            array_agg(stddev_r1 + (count_r2*count_r1/count_r1+count_r2)*power(avg_r2 - avg_r1, 2)),
            array_agg(count_w1+count_w2),
            array_agg(avg_w1 + (count_w2/(count_w1+count_w2))*(avg_w2-avg_w1)), array_agg(LEAST(min_w1, min_w2)), array_agg(GREATEST(max_w1, max_w2)),
            array_agg(stddev_w1 + (count_w2*count_w1/count_w1+count_w2)*power(avg_w2 - avg_w1, 2))
        INTO result FROM arrays;
    END IF;
    
    return result;
END;
$$
LANGUAGE 'plpgsql';

CREATE OR REPLACE FUNCTION fn_short_combine(short_array_agg_state, short_array_agg_state)
    RETURNS short_array_agg_state AS $$

DECLARE
    state1 ALIAS FOR $1;
    state2 ALIAS FOR $2;
    count integer;
    count_errors integer;
    result short_array_agg_state%ROWTYPE;

BEGIN

    -- Limit cases. 
    IF state1 is NULL
    THEN
        return state2;
    END IF;
    
    IF state2 is NULL
    THEN
        return state1;
    END IF;

    -- if there is a discrepancy in the arrays sizes
    IF CARDINALITY(state1.avg_r) != CARDINALITY(state2.avg_r) OR CARDINALITY(state1.avg_w) != CARDINALITY(state2.avg_w) THEN
        SELECT 0, 0,
        ARRAY[]::integer[], ARRAY[]::float8[], ARRAY[]::smallint[], ARRAY[]::smallint[], ARRAY[]::float8[],
        ARRAY[]::integer[], ARRAY[]::float8[], ARRAY[]::smallint[], ARRAY[]::smallint[], ARRAY[]::float8[]
        INTO result;
    ELSE
	
    count := state1.count + state2.count;
    count_errors := state1.count_errors + state2.count_errors;
    
    WITH arrays AS(
        SELECT 
            UNNEST(state1.count_r) AS count_r1, UNNEST(state1.avg_r) AS avg_r1,
            UNNEST(state1.min_r) AS min_r1, UNNEST(state1.max_r) AS max_r1, UNNEST(state1.stddev_r) AS stddev_r1,
            UNNEST(state1.count_w) AS count_w1, UNNEST(state1.avg_w) AS avg_w1,
            UNNEST(state1.min_w) AS min_w1, UNNEST(state1.max_w) AS max_w1, UNNEST(state1.stddev_w) AS stddev_w1,
            UNNEST(state2.count_r) AS count_r2, UNNEST(state2.avg_r) AS avg_r2,
            UNNEST(state2.min_r) AS min_r2, UNNEST(state2.max_r) AS max_r2, UNNEST(state2.stddev_r) AS stddev_r2,
            UNNEST(state2.count_w) AS count_w2, UNNEST(state2.avg_w) AS avg_w2,
            UNNEST(state2.min_w) AS min_w2, UNNEST(state2.max_w) AS max_w2, UNNEST(state2.stddev_w) AS stddev_w2
        )
        SELECT count, count_errors,
            array_agg(count_r1+count_r2),
            array_agg(avg_r1 + (count_r2/(count_r1+count_r2))*(avg_r2-avg_r1)), array_agg(LEAST(min_r1, min_r2)), array_agg(GREATEST(max_r1, max_r2)),
            array_agg(stddev_r1 + (count_r2*count_r1/count_r1+count_r2)*power(avg_r2 - avg_r1, 2)),
            array_agg(count_w1+count_w2),
            array_agg(avg_w1 + (count_w2/(count_w1+count_w2))*(avg_w2-avg_w1)), array_agg(LEAST(min_w1, min_w2)), array_agg(GREATEST(max_w1, max_w2)),
            array_agg(stddev_w1 + (count_w2*count_w1/count_w1+count_w2)*power(avg_w2 - avg_w1, 2))
        INTO result FROM arrays;
    END IF;
    
    return result;
END;
$$
LANGUAGE 'plpgsql';

CREATE OR REPLACE FUNCTION fn_ulong_combine(ulong_array_agg_state, ulong_array_agg_state)
    RETURNS ulong_array_agg_state AS $$

DECLARE
    state1 ALIAS FOR $1;
    state2 ALIAS FOR $2;
    count integer;
    count_errors integer;
    result ulong_array_agg_state%ROWTYPE;

BEGIN

    -- Limit cases. 
    IF state1 is NULL
    THEN
        return state2;
    END IF;
    
    IF state2 is NULL
    THEN
        return state1;
    END IF;

    -- if there is a discrepancy in the arrays sizes
    IF CARDINALITY(state1.avg_r) != CARDINALITY(state2.avg_r) OR CARDINALITY(state1.avg_w) != CARDINALITY(state2.avg_w) THEN
        SELECT 0, 0,
        ARRAY[]::integer[], ARRAY[]::float8[], ARRAY[]::ulong[], ARRAY[]::ulong[], ARRAY[]::float8[],
        ARRAY[]::integer[], ARRAY[]::float8[], ARRAY[]::ulong[], ARRAY[]::ulong[], ARRAY[]::float8[]
        INTO result;
    ELSE
	
    count := state1.count + state2.count;
    count_errors := state1.count_errors + state2.count_errors;
    
    WITH arrays AS(
        SELECT 
            UNNEST(state1.count_r) AS count_r1, UNNEST(state1.avg_r) AS avg_r1,
            UNNEST(state1.min_r) AS min_r1, UNNEST(state1.max_r) AS max_r1, UNNEST(state1.stddev_r) AS stddev_r1,
            UNNEST(state1.count_w) AS count_w1, UNNEST(state1.avg_w) AS avg_w1,
            UNNEST(state1.min_w) AS min_w1, UNNEST(state1.max_w) AS max_w1, UNNEST(state1.stddev_w) AS stddev_w1,
            UNNEST(state2.count_r) AS count_r2, UNNEST(state2.avg_r) AS avg_r2,
            UNNEST(state2.min_r) AS min_r2, UNNEST(state2.max_r) AS max_r2, UNNEST(state2.stddev_r) AS stddev_r2,
            UNNEST(state2.count_w) AS count_w2, UNNEST(state2.avg_w) AS avg_w2,
            UNNEST(state2.min_w) AS min_w2, UNNEST(state2.max_w) AS max_w2, UNNEST(state2.stddev_w) AS stddev_w2
        )
        SELECT count, count_errors,
            array_agg(count_r1+count_r2),
            array_agg(avg_r1 + (count_r2/(count_r1+count_r2))*(avg_r2-avg_r1)), array_agg(LEAST(min_r1, min_r2)), array_agg(GREATEST(max_r1, max_r2)),
            array_agg(stddev_r1 + (count_r2*count_r1/count_r1+count_r2)*power(avg_r2 - avg_r1, 2)),
            array_agg(count_w1+count_w2),
            array_agg(avg_w1 + (count_w2/(count_w1+count_w2))*(avg_w2-avg_w1)), array_agg(LEAST(min_w1, min_w2)), array_agg(GREATEST(max_w1, max_w2)),
            array_agg(stddev_w1 + (count_w2*count_w1/count_w1+count_w2)*power(avg_w2 - avg_w1, 2))
        INTO result FROM arrays;
    END IF;
    
    return result;
END;
$$
LANGUAGE 'plpgsql';

CREATE OR REPLACE FUNCTION fn_ulong64_combine(ulong64_array_agg_state, ulong64_array_agg_state)
    RETURNS ulong64_array_agg_state AS $$

DECLARE
    state1 ALIAS FOR $1;
    state2 ALIAS FOR $2;
    count integer;
    count_errors integer;
    result ulong64_array_agg_state%ROWTYPE;

BEGIN

    -- Limit cases. 
    IF state1 is NULL
    THEN
        return state2;
    END IF;
    
    IF state2 is NULL
    THEN
        return state1;
    END IF;

    -- if there is a discrepancy in the arrays sizes
    IF CARDINALITY(state1.avg_r) != CARDINALITY(state2.avg_r) OR CARDINALITY(state1.avg_w) != CARDINALITY(state2.avg_w) THEN
        SELECT 0, 0,
        ARRAY[]::integer[], ARRAY[]::float8[], ARRAY[]::ulong64[], ARRAY[]::ulong64[], ARRAY[]::float8[],
        ARRAY[]::integer[], ARRAY[]::float8[], ARRAY[]::ulong64[], ARRAY[]::ulong64[], ARRAY[]::float8[]
        INTO result;
    ELSE
	
    count := state1.count + state2.count;
    count_errors := state1.count_errors + state2.count_errors;
    
    WITH arrays AS(
        SELECT 
            UNNEST(state1.count_r) AS count_r1, UNNEST(state1.avg_r) AS avg_r1,
            UNNEST(state1.min_r) AS min_r1, UNNEST(state1.max_r) AS max_r1, UNNEST(state1.stddev_r) AS stddev_r1,
            UNNEST(state1.count_w) AS count_w1, UNNEST(state1.avg_w) AS avg_w1,
            UNNEST(state1.min_w) AS min_w1, UNNEST(state1.max_w) AS max_w1, UNNEST(state1.stddev_w) AS stddev_w1,
            UNNEST(state2.count_r) AS count_r2, UNNEST(state2.avg_r) AS avg_r2,
            UNNEST(state2.min_r) AS min_r2, UNNEST(state2.max_r) AS max_r2, UNNEST(state2.stddev_r) AS stddev_r2,
            UNNEST(state2.count_w) AS count_w2, UNNEST(state2.avg_w) AS avg_w2,
            UNNEST(state2.min_w) AS min_w2, UNNEST(state2.max_w) AS max_w2, UNNEST(state2.stddev_w) AS stddev_w2
        )
        SELECT count, count_errors,
            array_agg(count_r1+count_r2),
            array_agg(avg_r1 + (count_r2/(count_r1+count_r2))*(avg_r2-avg_r1)), array_agg(LEAST(min_r1, min_r2)), array_agg(GREATEST(max_r1, max_r2)),
            array_agg(stddev_r1 + (count_r2*count_r1/count_r1+count_r2)*power(avg_r2 - avg_r1, 2)),
            array_agg(count_w1+count_w2),
            array_agg(avg_w1 + (count_w2/(count_w1+count_w2))*(avg_w2-avg_w1)), array_agg(LEAST(min_w1, min_w2)), array_agg(GREATEST(max_w1, max_w2)),
            array_agg(stddev_w1 + (count_w2*count_w1/count_w1+count_w2)*power(avg_w2 - avg_w1, 2))
        INTO result FROM arrays;
    END IF;
    
    return result;
END;
$$
LANGUAGE 'plpgsql';

CREATE OR REPLACE FUNCTION fn_ushort_combine(ushort_array_agg_state, ushort_array_agg_state)
    RETURNS ushort_array_agg_state AS $$

DECLARE
    state1 ALIAS FOR $1;
    state2 ALIAS FOR $2;
    count integer;
    count_errors integer;
    result ushort_array_agg_state%ROWTYPE;

BEGIN

    -- Limit cases. 
    IF state1 is NULL
    THEN
        return state2;
    END IF;
    
    IF state2 is NULL
    THEN
        return state1;
    END IF;

    -- if there is a discrepancy in the arrays sizes
    IF CARDINALITY(state1.avg_r) != CARDINALITY(state2.avg_r) OR CARDINALITY(state1.avg_w) != CARDINALITY(state2.avg_w) THEN
        SELECT 0, 0,
        ARRAY[]::integer[], ARRAY[]::float8[], ARRAY[]::ushort[], ARRAY[]::ushort[], ARRAY[]::float8[],
        ARRAY[]::integer[], ARRAY[]::float8[], ARRAY[]::ushort[], ARRAY[]::ushort[], ARRAY[]::float8[]
        INTO result;
    ELSE
	
    count := state1.count + state2.count;
    count_errors := state1.count_errors + state2.count_errors;
    
    WITH arrays AS(
        SELECT 
            UNNEST(state1.count_r) AS count_r1, UNNEST(state1.avg_r) AS avg_r1,
            UNNEST(state1.min_r) AS min_r1, UNNEST(state1.max_r) AS max_r1, UNNEST(state1.stddev_r) AS stddev_r1,
            UNNEST(state1.count_w) AS count_w1, UNNEST(state1.avg_w) AS avg_w1,
            UNNEST(state1.min_w) AS min_w1, UNNEST(state1.max_w) AS max_w1, UNNEST(state1.stddev_w) AS stddev_w1,
            UNNEST(state2.count_r) AS count_r2, UNNEST(state2.avg_r) AS avg_r2,
            UNNEST(state2.min_r) AS min_r2, UNNEST(state2.max_r) AS max_r2, UNNEST(state2.stddev_r) AS stddev_r2,
            UNNEST(state2.count_w) AS count_w2, UNNEST(state2.avg_w) AS avg_w2,
            UNNEST(state2.min_w) AS min_w2, UNNEST(state2.max_w) AS max_w2, UNNEST(state2.stddev_w) AS stddev_w2
        )
        SELECT count, count_errors,
            array_agg(count_r1+count_r2),
            array_agg(avg_r1 + (count_r2/(count_r1+count_r2))*(avg_r2-avg_r1)), array_agg(LEAST(min_r1, min_r2)), array_agg(GREATEST(max_r1, max_r2)),
            array_agg(stddev_r1 + (count_r2*count_r1/count_r1+count_r2)*power(avg_r2 - avg_r1, 2)),
            array_agg(count_w1+count_w2),
            array_agg(avg_w1 + (count_w2/(count_w1+count_w2))*(avg_w2-avg_w1)), array_agg(LEAST(min_w1, min_w2)), array_agg(GREATEST(max_w1, max_w2)),
            array_agg(stddev_w1 + (count_w2*count_w1/count_w1+count_w2)*power(avg_w2 - avg_w1, 2))
        INTO result FROM arrays;
    END IF;
    
    return result;
END;
$$
LANGUAGE 'plpgsql';

-- Function to compute next aggregate from last state and current row
CREATE OR REPLACE FUNCTION fn_double_array_agg(double_array_agg_state,new_row att_array_devdouble)
    RETURNS double_array_agg_state AS $$

DECLARE
    state ALIAS FOR $1;
    count integer;
    count_err integer;
    result double_array_agg_state%ROWTYPE;

BEGIN

    -- Increment error count if needed
    IF new_row.att_error_desc_id THEN
        count_err = 1;
    ELSE
        count_err = 0;
    END IF;

    IF state is NULL
    THEN
        WITH arrays AS(
            SELECT UNNEST(new_row.value_r) AS read, UNNEST(new_row.value_w) AS write)
            SELECT 1, count_err,
            array_agg(
                CASE 
                    WHEN read='NaN'::float8 THEN 0 
                    WHEN read='Infinity'::float8 THEN 0 
                    WHEN read='-Infinity'::float8 THEN 0 
                    WHEN read IS NOT NULL THEN 1  
                    ELSE 0 
                END
                ), array_agg(
                CASE 
                    WHEN read='NaN'::float8 THEN 1 
                    WHEN read='Infinity'::float8 THEN 1 
                    WHEN read='-Infinity'::float8 THEN 1 
                    ELSE 0 
                END
            ), array_agg(read), array_agg(read), array_agg(read), array_agg(
                CASE 
                    WHEN read IS NOT NULL THEN 0 
                    ELSE read
                END
            ),
            array_agg(
                CASE 
                    WHEN write='NaN'::float8 THEN 0 
                    WHEN write='Infinity'::float8 THEN 0 
                    WHEN write='-Infinity'::float8 THEN 0 
                    WHEN write IS NOT NULL THEN 1 
                    ELSE 0 
                END
                ), array_agg(
                CASE 
                    WHEN write='NaN'::float8 THEN 1 
                    WHEN write='Infinity'::float8 THEN 1 
                    WHEN write='-Infinity'::float8 THEN 1 
                    ELSE 0 
                END
            ), array_agg(write), array_agg(write), array_agg(write), array_agg(
                CASE 
                    WHEN write IS NOT NULL THEN 0 
                    ELSE write
                END
            )
            INTO result FROM arrays;
    ELSE

        IF CARDINALITY(state.avg_r) != CARDINALITY(new_row.value_r) or CARDINALITY(state.avg_w) != CARDINALITY(new_row.value_w)
        THEN
            SELECT 0, 0,
            ARRAY[]::integer[], ARRAY[]::integer, ARRAY[]::float8[], ARRAY[]::float8[], ARRAY[]::float8[], ARRAY[]::float8[],
            ARRAY[]::integer[], ARRAY[]::integer, ARRAY[]::float8[], ARRAY[]::float8[], ARRAY[]::float8[], ARRAY[]::float8[]
            INTO result;
        ELSE

            count := state.count + 1;
            WITH arrays AS(
                SELECT UNNEST(new_row.value_r) AS read, UNNEST(new_row.value_w) AS write,
                    UNNEST(state.count_r) AS count_r, UNNEST(state.count_nan_r) AS nan_r, UNNEST(state.avg_r) AS avg_r,
                    UNNEST(state.min_r) AS min_r, UNNEST(state.max_r) AS max_r, UNNEST(state.stddev_r) AS stddev_r,
                    UNNEST(state.count_w) AS count_w, UNNEST(state.count_nan_w) AS nan_w, UNNEST(state.avg_w) AS avg_w,
                    UNNEST(state.min_w) AS min_w, UNNEST(state.max_w) AS max_w, UNNEST(state.stddev_w) AS stddev_w
                )
                SELECT count, state.count_errors+count_err
                 , array_agg(CASE
                        WHEN read='NaN'::float8 THEN count_r
                        WHEN read='Infinity'::float8 THEN count_r 
                        WHEN read='-Infinity'::float8 THEN count_r 
                        WHEN read IS NOT NULL THEN count_r+1 
                        ELSE count_r 
                    END
                    ), array_agg(CASE 
                        WHEN read='NaN'::float8 THEN nan_r + 1 
                        WHEN read='Infinity'::float8 THEN nan_r + 1 
                        WHEN read='-Infinity'::float8 THEN nan_r + 1 
                        ELSE nan_r 
                    END
                    ), array_agg(CASE 
                        WHEN read='NaN'::float8 THEN avg_r 
                        WHEN read='Infinity'::float8 THEN avg_r 
                        WHEN read='-Infinity'::float8 THEN avg_r
                        WHEN read IS NULL THEN avg_r
                        WHEN avg_r IS NULL THEN read
                        ELSE avg_r + (read-avg_r)/(count_r+1.)
                    END
                    ), array_agg(CASE 
                        WHEN read='NaN'::float8 THEN min_r 
                        WHEN read='Infinity'::float8 THEN min_r 
                        WHEN read='-Infinity'::float8 THEN min_r
                        ELSE LEAST(read, min_r)
                    END
                    ), array_agg(CASE 
                        WHEN read='NaN'::float8 THEN max_r 
                        WHEN read='Infinity'::float8 THEN max_r 
                        WHEN read='-Infinity'::float8 THEN max_r 
                        ELSE GREATEST(read, max_r)
                    END
                    ), array_agg(CASE 
                        WHEN read='NaN'::float8 THEN stddev_r 
                        WHEN read='Infinity'::float8 THEN stddev_r 
                        WHEN read='-Infinity'::float8 THEN stddev_r
                        WHEN read IS NULL THEN stddev_r
                        WHEN stddev_r IS NULL THEN 0
                        ELSE stddev_r + ((count_r+0.)/(count_r+1.))*power(read - avg_r, 2)
                    END
                    ), array_agg(CASE
                        WHEN write='NaN'::float8 THEN count_w
                        WHEN write='Infinity'::float8 THEN count_w 
                        WHEN write='-Infinity'::float8 THEN count_w 
                        WHEN write IS NOT NULL THEN count_w+1 
                        ELSE count_w 
                    END
                    ), array_agg(CASE 
                        WHEN write='NaN'::float8 THEN nan_w + 1 
                        WHEN write='Infinity'::float8 THEN nan_w + 1 
                        WHEN write='-Infinity'::float8 THEN nan_w + 1 
                        ELSE nan_w 
                    END
                    ), array_agg(CASE 
                        WHEN write='NaN'::float8 THEN avg_w 
                        WHEN write='Infinity'::float8 THEN avg_w 
                        WHEN write='-Infinity'::float8 THEN avg_w
                        WHEN write IS NULL THEN avg_w
                        WHEN avg_w IS NULL THEN write
                        ELSE avg_w + (write-avg_w)/(count_w+1.)
                    END
                    ), array_agg(CASE 
                        WHEN write='NaN'::float8 THEN min_w 
                        WHEN write='Infinity'::float8 THEN min_w 
                        WHEN write='-Infinity'::float8 THEN min_w
                        ELSE LEAST(write, min_w)
                    END
                    ), array_agg(CASE 
                        WHEN write='NaN'::float8 THEN max_w 
                        WHEN write='Infinity'::float8 THEN max_w 
                        WHEN write='-Infinity'::float8 THEN max_w 
                        ELSE GREATEST(write, max_w)
                    END
                    ), array_agg(CASE 
                        WHEN write='NaN'::float8 THEN stddev_w 
                        WHEN write='Infinity'::float8 THEN stddev_w 
                        WHEN write='-Infinity'::float8 THEN stddev_w
                        WHEN write IS NULL THEN stddev_w
                        WHEN stddev_w IS NULL THEN 0
                        ELSE stddev_w + ((count_w+0.)/(count_w+1.))*power(write - avg_w, 2)
                    END
                    )
                INTO result FROM arrays;
/*
* Different method using compute_element_agg

                SELECT n_count_r, n_count_nan_r, n_avg_r, n_min_r, n_max_r, n_stddev_r
                    , n_count_w, n_count_nan_w, n_avg_w, n_min_w, n_max_w, n_stddev_w
                    FROM compute_element_agg(
                         ( SELECT array_agg(ROW(read, write
                    , count_r, nan_r, avg_r, min_r, max_r, stddev_r
                    , count_w, nan_w, avg_w, min_w, max_w, stddev_w)::double_agg_input) from arrays )
                    ) as (n_count_r integer, n_count_nan_r integer, n_avg_r double precision, n_min_r double precision, n_max_r double precision, n_stddev_r double precision
                        , n_count_w integer, n_count_nan_w integer, n_avg_w double precision, n_min_w double precision, n_max_w double precision, n_stddev_w double precision)
                )
                SELECT count, state.count_errors+count_err
                , array_agg(aggregates.n_count_r), array_agg(aggregates.n_count_nan_r), array_agg(aggregates.n_avg_r), array_agg(aggregates.n_min_r), array_agg(aggregates.n_max_r), array_agg(aggregates.n_stddev_r)
                , array_agg(aggregates.n_count_w), array_agg(aggregates.n_count_nan_w), array_agg(aggregates.n_avg_w), array_agg(aggregates.n_min_w), array_agg(aggregates.n_max_w), array_agg(aggregates.n_stddev_w)
                into result from aggregates;
*/
        END IF;
    END IF;

    return result;

END;
$$
LANGUAGE 'plpgsql';

CREATE OR REPLACE FUNCTION fn_float_array_agg(float_array_agg_state,new_row att_array_devfloat)
    RETURNS float_array_agg_state AS $$

DECLARE
    state ALIAS FOR $1;
    count integer;
    count_err integer;
    result float_array_agg_state%ROWTYPE;

BEGIN

    -- Increment error count if needed
    IF new_row.att_error_desc_id THEN
        count_err = 1;
    ELSE
        count_err = 0;
    END IF;

    IF state is NULL
    THEN
        WITH arrays AS(
            SELECT UNNEST(new_row.value_r) AS read, UNNEST(new_row.value_w) AS write)
            SELECT 1, count_err,
            array_agg(
                CASE 
                    WHEN read='NaN'::float8 THEN 0 
                    WHEN read='Infinity'::float8 THEN 0 
                    WHEN read='-Infinity'::float8 THEN 0 
                    WHEN read IS NOT NULL THEN 1  
                    ELSE 0 
                END
                ), array_agg(
                CASE 
                    WHEN read='NaN'::float8 THEN 1 
                    WHEN read='Infinity'::float8 THEN 1 
                    WHEN read='-Infinity'::float8 THEN 1 
                    ELSE 0 
                END
            ), array_agg(read), array_agg(read), array_agg(read), array_agg(
                CASE 
                    WHEN read IS NOT NULL THEN 0 
                    ELSE read
                END
            ),
            array_agg(
                CASE 
                    WHEN write='NaN'::float8 THEN 0 
                    WHEN write='Infinity'::float8 THEN 0 
                    WHEN write='-Infinity'::float8 THEN 0 
                    WHEN write IS NOT NULL THEN 1 
                    ELSE 0 
                END
                ), array_agg(
                CASE 
                    WHEN write='NaN'::float8 THEN 1 
                    WHEN write='Infinity'::float8 THEN 1 
                    WHEN write='-Infinity'::float8 THEN 1 
                    ELSE 0 
                END
            ), array_agg(write), array_agg(write), array_agg(write), array_agg(
                CASE 
                    WHEN write IS NOT NULL THEN 0 
                    ELSE write
                END
            )
            INTO result FROM arrays;
    ELSE

        IF CARDINALITY(state.avg_r) != CARDINALITY(new_row.value_r) or CARDINALITY(state.avg_w) != CARDINALITY(new_row.value_w)
        THEN
            SELECT 0, 0,
            ARRAY[]::integer[], ARRAY[]::integer, ARRAY[]::float8[], ARRAY[]::real[], ARRAY[]::real[], ARRAY[]::float8[],
            ARRAY[]::integer[], ARRAY[]::integer, ARRAY[]::float8[], ARRAY[]::real[], ARRAY[]::real[], ARRAY[]::float8[]
            INTO result;
        ELSE

            count := state.count + 1;
            WITH arrays AS(
                SELECT UNNEST(new_row.value_r) AS read, UNNEST(new_row.value_w) AS write,
                    UNNEST(state.count_r) AS count_r, UNNEST(state.count_nan_r) AS nan_r, UNNEST(state.avg_r) AS avg_r,
                    UNNEST(state.min_r) AS min_r, UNNEST(state.max_r) AS max_r, UNNEST(state.stddev_r) AS stddev_r,
                    UNNEST(state.count_w) AS count_w, UNNEST(state.count_nan_w) AS nan_w, UNNEST(state.avg_w) AS avg_w,
                    UNNEST(state.min_w) AS min_w, UNNEST(state.max_w) AS max_w, UNNEST(state.stddev_w) AS stddev_w
                )
                SELECT count, state.count_errors+count_err
                 , array_agg(CASE
                        WHEN read='NaN'::float8 THEN count_r
                        WHEN read='Infinity'::float8 THEN count_r 
                        WHEN read='-Infinity'::float8 THEN count_r 
                        WHEN read IS NOT NULL THEN count_r+1 
                        ELSE count_r 
                    END
                    ), array_agg(CASE 
                        WHEN read='NaN'::float8 THEN nan_r + 1 
                        WHEN read='Infinity'::float8 THEN nan_r + 1 
                        WHEN read='-Infinity'::float8 THEN nan_r + 1 
                        ELSE nan_r 
                    END
                    ), array_agg(CASE 
                        WHEN read='NaN'::float8 THEN avg_r 
                        WHEN read='Infinity'::float8 THEN avg_r 
                        WHEN read='-Infinity'::float8 THEN avg_r
                        WHEN read IS NULL THEN avg_r
                        WHEN avg_r IS NULL THEN read
                        ELSE avg_r + (read-avg_r)/(count_r+1.)
                    END
                    ), array_agg(CASE 
                        WHEN read='NaN'::float8 THEN min_r 
                        WHEN read='Infinity'::float8 THEN min_r 
                        WHEN read='-Infinity'::float8 THEN min_r
                        ELSE LEAST(read, min_r)
                    END
                    ), array_agg(CASE 
                        WHEN read='NaN'::float8 THEN max_r 
                        WHEN read='Infinity'::float8 THEN max_r 
                        WHEN read='-Infinity'::float8 THEN max_r 
                        ELSE GREATEST(read, max_r)
                    END
                    ), array_agg(CASE 
                        WHEN read='NaN'::float8 THEN stddev_r 
                        WHEN read='Infinity'::float8 THEN stddev_r 
                        WHEN read='-Infinity'::float8 THEN stddev_r
                        WHEN read IS NULL THEN stddev_r
                        WHEN stddev_r IS NULL THEN 0
                        ELSE stddev_r + ((count_r+0.)/(count_r+1.))*power(read - avg_r, 2)
                    END
                    ), array_agg(CASE
                        WHEN write='NaN'::float8 THEN count_w
                        WHEN write='Infinity'::float8 THEN count_w 
                        WHEN write='-Infinity'::float8 THEN count_w 
                        WHEN write IS NOT NULL THEN count_w+1 
                        ELSE count_w 
                    END
                    ), array_agg(CASE 
                        WHEN write='NaN'::float8 THEN nan_w + 1 
                        WHEN write='Infinity'::float8 THEN nan_w + 1 
                        WHEN write='-Infinity'::float8 THEN nan_w + 1 
                        ELSE nan_w 
                    END
                    ), array_agg(CASE 
                        WHEN write='NaN'::float8 THEN avg_w 
                        WHEN write='Infinity'::float8 THEN avg_w 
                        WHEN write='-Infinity'::float8 THEN avg_w
                        WHEN write IS NULL THEN avg_w
                        WHEN avg_w IS NULL THEN write
                        ELSE avg_w + (write-avg_w)/(count_w+1.)
                    END
                    ), array_agg(CASE 
                        WHEN write='NaN'::float8 THEN min_w 
                        WHEN write='Infinity'::float8 THEN min_w 
                        WHEN write='-Infinity'::float8 THEN min_w
                        ELSE LEAST(write, min_w)
                    END
                    ), array_agg(CASE 
                        WHEN write='NaN'::float8 THEN max_w 
                        WHEN write='Infinity'::float8 THEN max_w 
                        WHEN write='-Infinity'::float8 THEN max_w 
                        ELSE GREATEST(write, max_w)
                    END
                    ), array_agg(CASE 
                        WHEN write='NaN'::float8 THEN stddev_w 
                        WHEN write='Infinity'::float8 THEN stddev_w 
                        WHEN write='-Infinity'::float8 THEN stddev_w
                        WHEN write IS NULL THEN stddev_w
                        WHEN stddev_w IS NULL THEN 0
                        ELSE stddev_w + ((count_w+0.)/(count_w+1.))*power(write - avg_w, 2)
                    END
                    )
                INTO result FROM arrays;
        END IF;
    END IF;

    return result;

END;
$$
LANGUAGE 'plpgsql';

CREATE OR REPLACE FUNCTION fn_long_array_agg(long_array_agg_state,new_row att_array_devlong)
    RETURNS long_array_agg_state AS $$

DECLARE
    state ALIAS FOR $1;
    count integer;
    count_err integer;
    result long_array_agg_state%ROWTYPE;

BEGIN

    -- Increment error count if needed
    IF new_row.att_error_desc_id THEN
        count_err = 1;
    ELSE
        count_err = 0;
    END IF;

    IF state is NULL
    THEN
        WITH arrays AS(
            SELECT UNNEST(new_row.value_r) AS read, UNNEST(new_row.value_w) AS write)
            SELECT 1, count_err,
            array_agg(
                CASE 
                    WHEN read IS NOT NULL THEN 1  
                    ELSE 0 
                END
            ), array_agg(read), array_agg(read), array_agg(read), array_agg(
                CASE 
                    WHEN read IS NOT NULL THEN 0 
                    ELSE read
                END
            ),
            array_agg(
                CASE 
                    WHEN write IS NOT NULL THEN 1 
                    ELSE 0 
                END
            ), array_agg(write), array_agg(write), array_agg(write), array_agg(
                CASE 
                    WHEN write IS NOT NULL THEN 0 
                    ELSE write
                END
            )
            INTO result FROM arrays;
    ELSE

        IF CARDINALITY(state.avg_r) != CARDINALITY(new_row.value_r) or CARDINALITY(state.avg_w) != CARDINALITY(new_row.value_w)
        THEN
            SELECT 0, 0,
            ARRAY[]::integer[], ARRAY[]::float8[], ARRAY[]::integer[], ARRAY[]::integer[], ARRAY[]::float8[],
            ARRAY[]::integer[], ARRAY[]::float8[], ARRAY[]::integer[], ARRAY[]::integer[], ARRAY[]::float8[]
            INTO result;
        ELSE

            count := state.count + 1;
            WITH arrays AS(
                SELECT UNNEST(new_row.value_r) AS read, UNNEST(new_row.value_w) AS write,
                    UNNEST(state.count_r) AS count_r, UNNEST(state.avg_r) AS avg_r,
                    UNNEST(state.min_r) AS min_r, UNNEST(state.max_r) AS max_r, UNNEST(state.stddev_r) AS stddev_r,
                    UNNEST(state.count_w) AS count_w, UNNEST(state.avg_w) AS avg_w,
                    UNNEST(state.min_w) AS min_w, UNNEST(state.max_w) AS max_w, UNNEST(state.stddev_w) AS stddev_w
                )
                SELECT count, state.count_errors+count_err
                 , array_agg(CASE
                        WHEN read IS NOT NULL THEN count_r+1 
                        ELSE count_r 
                    END
                    ), array_agg(CASE 
                        WHEN read IS NULL THEN avg_r
                        WHEN avg_r IS NULL THEN read
                        ELSE avg_r + (read-avg_r)/(count_r+1.)
                    END
                    ), array_agg(LEAST(read, min_r)), array_agg(GREATEST(read, max_r))
                    , array_agg(CASE 
                        WHEN read IS NULL THEN stddev_r
                        WHEN stddev_r IS NULL THEN 0
                        ELSE stddev_r + ((count_r+0.)/(count_r+1.))*power(read - avg_r, 2)
                    END
                    ), array_agg(CASE
                        WHEN write IS NOT NULL THEN count_w+1 
                        ELSE count_w 
                    END
                    ), array_agg(CASE 
                        WHEN write IS NULL THEN avg_w
                        WHEN avg_w IS NULL THEN write
                        ELSE avg_w + (write-avg_w)/(count_w+1.)
                    END
                    ), array_agg(LEAST(write, min_w)), array_agg(GREATEST(write, max_w))
                    , array_agg(CASE 
                        WHEN write IS NULL THEN stddev_w
                        WHEN stddev_w IS NULL THEN 0
                        ELSE stddev_w + ((count_w+0.)/(count_w+1.))*power(write - avg_w, 2)
                    END
                    )
                INTO result FROM arrays;
        END IF;
    END IF;

    return result;

END;
$$
LANGUAGE 'plpgsql';

CREATE OR REPLACE FUNCTION fn_long64_array_agg(long64_array_agg_state,new_row att_array_devlong64)
    RETURNS long64_array_agg_state AS $$

DECLARE
    state ALIAS FOR $1;
    count integer;
    count_err integer;
    result long64_array_agg_state%ROWTYPE;

BEGIN

    -- Increment error count if needed
    IF new_row.att_error_desc_id THEN
        count_err = 1;
    ELSE
        count_err = 0;
    END IF;

    IF state is NULL
    THEN
        WITH arrays AS(
            SELECT UNNEST(new_row.value_r) AS read, UNNEST(new_row.value_w) AS write)
            SELECT 1, count_err,
            array_agg(
                CASE 
                    WHEN read IS NOT NULL THEN 1  
                    ELSE 0 
                END
            ), array_agg(read), array_agg(read), array_agg(read), array_agg(
                CASE 
                    WHEN read IS NOT NULL THEN 0 
                    ELSE read
                END
            ),
            array_agg(
                CASE 
                    WHEN write IS NOT NULL THEN 1 
                    ELSE 0 
                END
            ), array_agg(write), array_agg(write), array_agg(write), array_agg(
                CASE 
                    WHEN write IS NOT NULL THEN 0 
                    ELSE write
                END
            )
            INTO result FROM arrays;
    ELSE

        IF CARDINALITY(state.avg_r) != CARDINALITY(new_row.value_r) or CARDINALITY(state.avg_w) != CARDINALITY(new_row.value_w)
        THEN
            SELECT 0, 0,
            ARRAY[]::integer[], ARRAY[]::float8[], ARRAY[]::bigint[], ARRAY[]::bigint[], ARRAY[]::float8[],
            ARRAY[]::integer[], ARRAY[]::float8[], ARRAY[]::bigint[], ARRAY[]::bigint[], ARRAY[]::float8[]
            INTO result;
        ELSE

            count := state.count + 1;
            WITH arrays AS(
                SELECT UNNEST(new_row.value_r) AS read, UNNEST(new_row.value_w) AS write,
                    UNNEST(state.count_r) AS count_r, UNNEST(state.avg_r) AS avg_r,
                    UNNEST(state.min_r) AS min_r, UNNEST(state.max_r) AS max_r, UNNEST(state.stddev_r) AS stddev_r,
                    UNNEST(state.count_w) AS count_w, UNNEST(state.avg_w) AS avg_w,
                    UNNEST(state.min_w) AS min_w, UNNEST(state.max_w) AS max_w, UNNEST(state.stddev_w) AS stddev_w
                )
                SELECT count, state.count_errors+count_err
                 , array_agg(CASE
                        WHEN read IS NOT NULL THEN count_r+1 
                        ELSE count_r 
                    END
                    ), array_agg(CASE 
                        WHEN read IS NULL THEN avg_r
                        WHEN avg_r IS NULL THEN read
                        ELSE avg_r + (read-avg_r)/(count_r+1.)
                    END
                    ), array_agg(LEAST(read, min_r)), array_agg(GREATEST(read, max_r))
                    , array_agg(CASE 
                        WHEN read IS NULL THEN stddev_r
                        WHEN stddev_r IS NULL THEN 0
                        ELSE stddev_r + ((count_r+0.)/(count_r+1.))*power(read - avg_r, 2)
                    END
                    ), array_agg(CASE
                        WHEN write IS NOT NULL THEN count_w+1 
                        ELSE count_w 
                    END
                    ), array_agg(CASE 
                        WHEN write IS NULL THEN avg_w
                        WHEN avg_w IS NULL THEN write
                        ELSE avg_w + (write-avg_w)/(count_w+1.)
                    END
                    ), array_agg(LEAST(write, min_w)), array_agg(GREATEST(write, max_w))
                    , array_agg(CASE 
                        WHEN write IS NULL THEN stddev_w
                        WHEN stddev_w IS NULL THEN 0
                        ELSE stddev_w + ((count_w+0.)/(count_w+1.))*power(write - avg_w, 2)
                    END
                    )
                INTO result FROM arrays;
        END IF;
    END IF;

    return result;

END;
$$
LANGUAGE 'plpgsql';

CREATE OR REPLACE FUNCTION fn_short_array_agg(short_array_agg_state,new_row att_array_devshort)
    RETURNS short_array_agg_state AS $$

DECLARE
    state ALIAS FOR $1;
    count integer;
    count_err integer;
    result short_array_agg_state%ROWTYPE;

BEGIN

    -- Increment error count if needed
    IF new_row.att_error_desc_id THEN
        count_err = 1;
    ELSE
        count_err = 0;
    END IF;

    IF state is NULL
    THEN
        WITH arrays AS(
            SELECT UNNEST(new_row.value_r) AS read, UNNEST(new_row.value_w) AS write)
            SELECT 1, count_err,
            array_agg(
                CASE 
                    WHEN read IS NOT NULL THEN 1  
                    ELSE 0 
                END
            ), array_agg(read), array_agg(read), array_agg(read), array_agg(
                CASE 
                    WHEN read IS NOT NULL THEN 0 
                    ELSE read
                END
            ),
            array_agg(
                CASE 
                    WHEN write IS NOT NULL THEN 1 
                    ELSE 0 
                END
            ), array_agg(write), array_agg(write), array_agg(write), array_agg(
                CASE 
                    WHEN write IS NOT NULL THEN 0 
                    ELSE write
                END
            )
            INTO result FROM arrays;
    ELSE

        IF CARDINALITY(state.avg_r) != CARDINALITY(new_row.value_r) or CARDINALITY(state.avg_w) != CARDINALITY(new_row.value_w)
        THEN
            SELECT 0, 0,
            ARRAY[]::integer[], ARRAY[]::float8[], ARRAY[]::smallint[], ARRAY[]::smallint[], ARRAY[]::float8[],
            ARRAY[]::integer[], ARRAY[]::float8[], ARRAY[]::smallint[], ARRAY[]::smallint[], ARRAY[]::float8[]
            INTO result;
        ELSE

            count := state.count + 1;
            WITH arrays AS(
                SELECT UNNEST(new_row.value_r) AS read, UNNEST(new_row.value_w) AS write,
                    UNNEST(state.count_r) AS count_r, UNNEST(state.avg_r) AS avg_r,
                    UNNEST(state.min_r) AS min_r, UNNEST(state.max_r) AS max_r, UNNEST(state.stddev_r) AS stddev_r,
                    UNNEST(state.count_w) AS count_w, UNNEST(state.avg_w) AS avg_w,
                    UNNEST(state.min_w) AS min_w, UNNEST(state.max_w) AS max_w, UNNEST(state.stddev_w) AS stddev_w
                )
                SELECT count, state.count_errors+count_err
                 , array_agg(CASE
                        WHEN read IS NOT NULL THEN count_r+1 
                        ELSE count_r 
                    END
                    ), array_agg(CASE 
                        WHEN read IS NULL THEN avg_r
                        WHEN avg_r IS NULL THEN read
                        ELSE avg_r + (read-avg_r)/(count_r+1.)
                    END
                    ), array_agg(LEAST(read, min_r)), array_agg(GREATEST(read, max_r))
                    , array_agg(CASE 
                        WHEN read IS NULL THEN stddev_r
                        WHEN stddev_r IS NULL THEN 0
                        ELSE stddev_r + ((count_r+0.)/(count_r+1.))*power(read - avg_r, 2)
                    END
                    ), array_agg(CASE
                        WHEN write IS NOT NULL THEN count_w+1 
                        ELSE count_w 
                    END
                    ), array_agg(CASE 
                        WHEN write IS NULL THEN avg_w
                        WHEN avg_w IS NULL THEN write
                        ELSE avg_w + (write-avg_w)/(count_w+1.)
                    END
                    ), array_agg(LEAST(write, min_w)), array_agg(GREATEST(write, max_w))
                    , array_agg(CASE 
                        WHEN write IS NULL THEN stddev_w
                        WHEN stddev_w IS NULL THEN 0
                        ELSE stddev_w + ((count_w+0.)/(count_w+1.))*power(write - avg_w, 2)
                    END
                    )
                INTO result FROM arrays;
        END IF;
    END IF;

    return result;

END;
$$
LANGUAGE 'plpgsql';

CREATE OR REPLACE FUNCTION fn_ulong_array_agg(ulong_array_agg_state,new_row att_array_devulong)
    RETURNS ulong_array_agg_state AS $$

DECLARE
    state ALIAS FOR $1;
    count integer;
    count_err integer;
    result ulong_array_agg_state%ROWTYPE;

BEGIN

    -- Increment error count if needed
    IF new_row.att_error_desc_id THEN
        count_err = 1;
    ELSE
        count_err = 0;
    END IF;

    IF state is NULL
    THEN
        WITH arrays AS(
            SELECT UNNEST(new_row.value_r) AS read, UNNEST(new_row.value_w) AS write)
            SELECT 1, count_err,
            array_agg(
                CASE 
                    WHEN read IS NOT NULL THEN 1  
                    ELSE 0 
                END
            ), array_agg(read), array_agg(read), array_agg(read), array_agg(
                CASE 
                    WHEN read IS NOT NULL THEN 0 
                    ELSE read
                END
            ),
            array_agg(
                CASE 
                    WHEN write IS NOT NULL THEN 1 
                    ELSE 0 
                END
            ), array_agg(write), array_agg(write), array_agg(write), array_agg(
                CASE 
                    WHEN write IS NOT NULL THEN 0 
                    ELSE write
                END
            )
            INTO result FROM arrays;
    ELSE

        IF CARDINALITY(state.avg_r) != CARDINALITY(new_row.value_r) or CARDINALITY(state.avg_w) != CARDINALITY(new_row.value_w)
        THEN
            SELECT 0, 0,
            ARRAY[]::integer[], ARRAY[]::float8[], ARRAY[]::ulong[], ARRAY[]::ulong[], ARRAY[]::float8[],
            ARRAY[]::integer[], ARRAY[]::float8[], ARRAY[]::ulong[], ARRAY[]::ulong[], ARRAY[]::float8[]
            INTO result;
        ELSE

            count := state.count + 1;
            WITH arrays AS(
                SELECT UNNEST(new_row.value_r) AS read, UNNEST(new_row.value_w) AS write,
                    UNNEST(state.count_r) AS count_r, UNNEST(state.avg_r) AS avg_r,
                    UNNEST(state.min_r) AS min_r, UNNEST(state.max_r) AS max_r, UNNEST(state.stddev_r) AS stddev_r,
                    UNNEST(state.count_w) AS count_w, UNNEST(state.avg_w) AS avg_w,
                    UNNEST(state.min_w) AS min_w, UNNEST(state.max_w) AS max_w, UNNEST(state.stddev_w) AS stddev_w
                )
                SELECT count, state.count_errors+count_err
                 , array_agg(CASE
                        WHEN read IS NOT NULL THEN count_r+1 
                        ELSE count_r 
                    END
                    ), array_agg(CASE 
                        WHEN read IS NULL THEN avg_r
                        WHEN avg_r IS NULL THEN read
                        ELSE avg_r + (read-avg_r)/(count_r+1.)
                    END
                    ), array_agg(LEAST(read, min_r)), array_agg(GREATEST(read, max_r))
                    , array_agg(CASE 
                        WHEN read IS NULL THEN stddev_r
                        WHEN stddev_r IS NULL THEN 0
                        ELSE stddev_r + ((count_r+0.)/(count_r+1.))*power(read - avg_r, 2)
                    END
                    ), array_agg(CASE
                        WHEN write IS NOT NULL THEN count_w+1 
                        ELSE count_w 
                    END
                    ), array_agg(CASE 
                        WHEN write IS NULL THEN avg_w
                        WHEN avg_w IS NULL THEN write
                        ELSE avg_w + (write-avg_w)/(count_w+1.)
                    END
                    ), array_agg(LEAST(write, min_w)), array_agg(GREATEST(write, max_w))
                    , array_agg(CASE 
                        WHEN write IS NULL THEN stddev_w
                        WHEN stddev_w IS NULL THEN 0
                        ELSE stddev_w + ((count_w+0.)/(count_w+1.))*power(write - avg_w, 2)
                    END
                    )
                INTO result FROM arrays;
        END IF;
    END IF;

    return result;

END;
$$
LANGUAGE 'plpgsql';

CREATE OR REPLACE FUNCTION fn_ulong64_array_agg(ulong64_array_agg_state,new_row att_array_devulong64)
    RETURNS ulong64_array_agg_state AS $$

DECLARE
    state ALIAS FOR $1;
    count integer;
    count_err integer;
    result ulong64_array_agg_state%ROWTYPE;

BEGIN

    -- Increment error count if needed
    IF new_row.att_error_desc_id THEN
        count_err = 1;
    ELSE
        count_err = 0;
    END IF;

    IF state is NULL
    THEN
        WITH arrays AS(
            SELECT UNNEST(new_row.value_r) AS read, UNNEST(new_row.value_w) AS write)
            SELECT 1, count_err,
            array_agg(
                CASE 
                    WHEN read IS NOT NULL THEN 1  
                    ELSE 0 
                END
            ), array_agg(read), array_agg(read), array_agg(read), array_agg(
                CASE 
                    WHEN read IS NOT NULL THEN 0 
                    ELSE read
                END
            ),
            array_agg(
                CASE 
                    WHEN write IS NOT NULL THEN 1 
                    ELSE 0 
                END
            ), array_agg(write), array_agg(write), array_agg(write), array_agg(
                CASE 
                    WHEN write IS NOT NULL THEN 0 
                    ELSE write
                END
            )
            INTO result FROM arrays;
    ELSE

        IF CARDINALITY(state.avg_r) != CARDINALITY(new_row.value_r) or CARDINALITY(state.avg_w) != CARDINALITY(new_row.value_w)
        THEN
            SELECT 0, 0,
            ARRAY[]::integer[], ARRAY[]::float8[], ARRAY[]::ulong64[], ARRAY[]::ulong64[], ARRAY[]::float8[],
            ARRAY[]::integer[], ARRAY[]::float8[], ARRAY[]::ulong64[], ARRAY[]::ulong64[], ARRAY[]::float8[]
            INTO result;
        ELSE

            count := state.count + 1;
            WITH arrays AS(
                SELECT UNNEST(new_row.value_r) AS read, UNNEST(new_row.value_w) AS write,
                    UNNEST(state.count_r) AS count_r, UNNEST(state.avg_r) AS avg_r,
                    UNNEST(state.min_r) AS min_r, UNNEST(state.max_r) AS max_r, UNNEST(state.stddev_r) AS stddev_r,
                    UNNEST(state.count_w) AS count_w, UNNEST(state.avg_w) AS avg_w,
                    UNNEST(state.min_w) AS min_w, UNNEST(state.max_w) AS max_w, UNNEST(state.stddev_w) AS stddev_w
                )
                SELECT count, state.count_errors+count_err
                 , array_agg(CASE
                        WHEN read IS NOT NULL THEN count_r+1 
                        ELSE count_r 
                    END
                    ), array_agg(CASE 
                        WHEN read IS NULL THEN avg_r
                        WHEN avg_r IS NULL THEN read
                        ELSE avg_r + (read-avg_r)/(count_r+1.)
                    END
                    ), array_agg(LEAST(read, min_r)), array_agg(GREATEST(read, max_r))
                    , array_agg(CASE 
                        WHEN read IS NULL THEN stddev_r
                        WHEN stddev_r IS NULL THEN 0
                        ELSE stddev_r + ((count_r+0.)/(count_r+1.))*power(read - avg_r, 2)
                    END
                    ), array_agg(CASE
                        WHEN write IS NOT NULL THEN count_w+1 
                        ELSE count_w 
                    END
                    ), array_agg(CASE 
                        WHEN write IS NULL THEN avg_w
                        WHEN avg_w IS NULL THEN write
                        ELSE avg_w + (write-avg_w)/(count_w+1.)
                    END
                    ), array_agg(LEAST(write, min_w)), array_agg(GREATEST(write, max_w))
                    , array_agg(CASE 
                        WHEN write IS NULL THEN stddev_w
                        WHEN stddev_w IS NULL THEN 0
                        ELSE stddev_w + ((count_w+0.)/(count_w+1.))*power(write - avg_w, 2)
                    END
                    )
                INTO result FROM arrays;
        END IF;
    END IF;

    return result;

END;
$$
LANGUAGE 'plpgsql';

CREATE OR REPLACE FUNCTION fn_ushort_array_agg(ushort_array_agg_state,new_row att_array_devushort)
    RETURNS ushort_array_agg_state AS $$

DECLARE
    state ALIAS FOR $1;
    count integer;
    count_err integer;
    result ushort_array_agg_state%ROWTYPE;

BEGIN

    -- Increment error count if needed
    IF new_row.att_error_desc_id THEN
        count_err = 1;
    ELSE
        count_err = 0;
    END IF;

    IF state is NULL
    THEN
        WITH arrays AS(
            SELECT UNNEST(new_row.value_r) AS read, UNNEST(new_row.value_w) AS write)
            SELECT 1, count_err,
            array_agg(
                CASE 
                    WHEN read IS NOT NULL THEN 1  
                    ELSE 0 
                END
            ), array_agg(read), array_agg(read), array_agg(read), array_agg(
                CASE 
                    WHEN read IS NOT NULL THEN 0 
                    ELSE read
                END
            ),
            array_agg(
                CASE 
                    WHEN write IS NOT NULL THEN 1 
                    ELSE 0 
                END
            ), array_agg(write), array_agg(write), array_agg(write), array_agg(
                CASE 
                    WHEN write IS NOT NULL THEN 0 
                    ELSE write
                END
            )
            INTO result FROM arrays;
    ELSE

        IF CARDINALITY(state.avg_r) != CARDINALITY(new_row.value_r) or CARDINALITY(state.avg_w) != CARDINALITY(new_row.value_w)
        THEN
            SELECT 0, 0,
            ARRAY[]::integer[], ARRAY[]::float8[], ARRAY[]::ushort[], ARRAY[]::ushort[], ARRAY[]::float8[],
            ARRAY[]::integer[], ARRAY[]::float8[], ARRAY[]::ushort[], ARRAY[]::ushort[], ARRAY[]::float8[]
            INTO result;
        ELSE

            count := state.count + 1;
            WITH arrays AS(
                SELECT UNNEST(new_row.value_r) AS read, UNNEST(new_row.value_w) AS write,
                    UNNEST(state.count_r) AS count_r, UNNEST(state.avg_r) AS avg_r,
                    UNNEST(state.min_r) AS min_r, UNNEST(state.max_r) AS max_r, UNNEST(state.stddev_r) AS stddev_r,
                    UNNEST(state.count_w) AS count_w, UNNEST(state.avg_w) AS avg_w,
                    UNNEST(state.min_w) AS min_w, UNNEST(state.max_w) AS max_w, UNNEST(state.stddev_w) AS stddev_w
                )
                SELECT count, state.count_errors+count_err
                 , array_agg(CASE
                        WHEN read IS NOT NULL THEN count_r+1 
                        ELSE count_r 
                    END
                    ), array_agg(CASE 
                        WHEN read IS NULL THEN avg_r
                        WHEN avg_r IS NULL THEN read
                        ELSE avg_r + (read-avg_r)/(count_r+1.)
                    END
                    ), array_agg(LEAST(read, min_r)), array_agg(GREATEST(read, max_r))
                    , array_agg(CASE 
                        WHEN read IS NULL THEN stddev_r
                        WHEN stddev_r IS NULL THEN 0
                        ELSE stddev_r + ((count_r+0.)/(count_r+1.))*power(read - avg_r, 2)
                    END
                    ), array_agg(CASE
                        WHEN write IS NOT NULL THEN count_w+1 
                        ELSE count_w 
                    END
                    ), array_agg(CASE 
                        WHEN write IS NULL THEN avg_w
                        WHEN avg_w IS NULL THEN write
                        ELSE avg_w + (write-avg_w)/(count_w+1.)
                    END
                    ), array_agg(LEAST(write, min_w)), array_agg(GREATEST(write, max_w))
                    , array_agg(CASE 
                        WHEN write IS NULL THEN stddev_w
                        WHEN stddev_w IS NULL THEN 0
                        ELSE stddev_w + ((count_w+0.)/(count_w+1.))*power(write - avg_w, 2)
                    END
                    )
                INTO result FROM arrays;
        END IF;
    END IF;

    return result;

END;
$$
LANGUAGE 'plpgsql';

-- Function to compute the real aggregate results from the internal state
-- in this case only the stddev has to be computed
CREATE OR REPLACE FUNCTION fn_double_array_final(double_array_agg_state)
    RETURNS double_array_agg_state AS $$

DECLARE
    state ALIAS FOR $1;
    result double_array_agg_state%ROWTYPE;

BEGIN

    IF state IS NULL
    THEN
        return NULL;
    END IF;

    IF state.count = 0 THEN
        return NULL;

    ELSE
        WITH arrays AS(
            SELECT UNNEST(state.count_r) AS count_r, UNNEST(state.stddev_r) AS stddev_r,
                UNNEST(state.count_w) AS count_w, UNNEST(state.stddev_w) AS stddev_w
            )
            SELECT state.count, state.count_errors,
            state.count_r, state.count_nan_r, state.avg_r, 
            state.min_r, state.max_r, array_agg(sqrt(stddev_r/(count_r))),
            state.count_w, state.count_nan_w, state.avg_w, 
            state.min_w, state.max_w, array_agg(sqrt(stddev_w/(count_w)))
            INTO result FROM arrays;

        return result;

    END IF;
END;
$$
LANGUAGE 'plpgsql';

CREATE OR REPLACE FUNCTION fn_float_array_final(float_array_agg_state)
    RETURNS float_array_agg_state AS $$

DECLARE
    state ALIAS FOR $1;
    result float_array_agg_state%ROWTYPE;

BEGIN

    IF state IS NULL
    THEN
        return NULL;
    END IF;

    IF state.count = 0 THEN
        return NULL;

    ELSE
        WITH arrays AS(
            SELECT UNNEST(state.count_r) AS count_r, UNNEST(state.stddev_r) AS stddev_r,
                UNNEST(state.count_w) AS count_w, UNNEST(state.stddev_w) AS stddev_w
            )
            SELECT state.count, state.count_errors,
            state.count_r, state.count_nan_r, state.avg_r, 
            state.min_r, state.max_r, array_agg(sqrt(stddev_r/(count_r))),
            state.count_w, state.count_nan_w, state.avg_w, 
            state.min_w, state.max_w, array_agg(sqrt(stddev_w/(count_w)))
            INTO result FROM arrays;

        return result;

    END IF;
END;
$$
LANGUAGE 'plpgsql';

CREATE OR REPLACE FUNCTION fn_long_array_final(long_array_agg_state)
    RETURNS long_array_agg_state AS $$

DECLARE
    state ALIAS FOR $1;
    result long_array_agg_state%ROWTYPE;

BEGIN

    IF state IS NULL
    THEN
        return NULL;
    END IF;

    IF state.count = 0 THEN
        return NULL;

    ELSE
        WITH arrays AS(
            SELECT UNNEST(state.count_r) AS count_r, UNNEST(state.stddev_r) AS stddev_r,
                UNNEST(state.count_w) AS count_w, UNNEST(state.stddev_w) AS stddev_w
            )
            SELECT state.count, state.count_errors,
            state.count_r, state.avg_r, 
            state.min_r, state.max_r, array_agg(sqrt(stddev_r/(count_r))),
            state.count_w, state.avg_w, 
            state.min_w, state.max_w, array_agg(sqrt(stddev_w/(count_w)))
            INTO result FROM arrays;

        return result;

    END IF;
END;
$$
LANGUAGE 'plpgsql';

CREATE OR REPLACE FUNCTION fn_long64_array_final(long64_array_agg_state)
    RETURNS long64_array_agg_state AS $$

DECLARE
    state ALIAS FOR $1;
    result long64_array_agg_state%ROWTYPE;

BEGIN

    IF state IS NULL
    THEN
        return NULL;
    END IF;

    IF state.count = 0 THEN
        return NULL;

    ELSE
        WITH arrays AS(
            SELECT UNNEST(state.count_r) AS count_r, UNNEST(state.stddev_r) AS stddev_r,
                UNNEST(state.count_w) AS count_w, UNNEST(state.stddev_w) AS stddev_w
            )
            SELECT state.count, state.count_errors,
            state.count_r, state.avg_r, 
            state.min_r, state.max_r, array_agg(sqrt(stddev_r/(count_r))),
            state.count_w, state.avg_w, 
            state.min_w, state.max_w, array_agg(sqrt(stddev_w/(count_w)))
            INTO result FROM arrays;

        return result;

    END IF;
END;
$$
LANGUAGE 'plpgsql';

CREATE OR REPLACE FUNCTION fn_short_array_final(short_array_agg_state)
    RETURNS short_array_agg_state AS $$

DECLARE
    state ALIAS FOR $1;
    result short_array_agg_state%ROWTYPE;

BEGIN

    IF state IS NULL
    THEN
        return NULL;
    END IF;

    IF state.count = 0 THEN
        return NULL;

    ELSE
        WITH arrays AS(
            SELECT UNNEST(state.count_r) AS count_r, UNNEST(state.stddev_r) AS stddev_r,
                UNNEST(state.count_w) AS count_w, UNNEST(state.stddev_w) AS stddev_w
            )
            SELECT state.count, state.count_errors,
            state.count_r, state.avg_r, 
            state.min_r, state.max_r, array_agg(sqrt(stddev_r/(count_r))),
            state.count_w, state.avg_w, 
            state.min_w, state.max_w, array_agg(sqrt(stddev_w/(count_w)))
            INTO result FROM arrays;

        return result;

    END IF;
END;
$$
LANGUAGE 'plpgsql';

CREATE OR REPLACE FUNCTION fn_ulong_array_final(ulong_array_agg_state)
    RETURNS ulong_array_agg_state AS $$

DECLARE
    state ALIAS FOR $1;
    result ulong_array_agg_state%ROWTYPE;

BEGIN

    IF state IS NULL
    THEN
        return NULL;
    END IF;

    IF state.count = 0 THEN
        return NULL;

    ELSE
        WITH arrays AS(
            SELECT UNNEST(state.count_r) AS count_r, UNNEST(state.stddev_r) AS stddev_r,
                UNNEST(state.count_w) AS count_w, UNNEST(state.stddev_w) AS stddev_w
            )
            SELECT state.count, state.count_errors,
            state.count_r, state.avg_r, 
            state.min_r, state.max_r, array_agg(sqrt(stddev_r/(count_r))),
            state.count_w, state.avg_w, 
            state.min_w, state.max_w, array_agg(sqrt(stddev_w/(count_w)))
            INTO result FROM arrays;

        return result;

    END IF;
END;
$$
LANGUAGE 'plpgsql';

CREATE OR REPLACE FUNCTION fn_ulong64_array_final(ulong64_array_agg_state)
    RETURNS ulong64_array_agg_state AS $$

DECLARE
    state ALIAS FOR $1;
    result ulong64_array_agg_state%ROWTYPE;

BEGIN

    IF state IS NULL
    THEN
        return NULL;
    END IF;

    IF state.count = 0 THEN
        return NULL;

    ELSE
        WITH arrays AS(
            SELECT UNNEST(state.count_r) AS count_r, UNNEST(state.stddev_r) AS stddev_r,
                UNNEST(state.count_w) AS count_w, UNNEST(state.stddev_w) AS stddev_w
            )
            SELECT state.count, state.count_errors,
            state.count_r, state.avg_r, 
            state.min_r, state.max_r, array_agg(sqrt(stddev_r/(count_r))),
            state.count_w, state.avg_w, 
            state.min_w, state.max_w, array_agg(sqrt(stddev_w/(count_w)))
            INTO result FROM arrays;

        return result;

    END IF;
END;
$$
LANGUAGE 'plpgsql';

CREATE OR REPLACE FUNCTION fn_ushort_array_final(ushort_array_agg_state)
    RETURNS ushort_array_agg_state AS $$

DECLARE
    state ALIAS FOR $1;
    result ushort_array_agg_state%ROWTYPE;

BEGIN

    IF state IS NULL
    THEN
        return NULL;
    END IF;

    IF state.count = 0 THEN
        return NULL;

    ELSE
        WITH arrays AS(
            SELECT UNNEST(state.count_r) AS count_r, UNNEST(state.stddev_r) AS stddev_r,
                UNNEST(state.count_w) AS count_w, UNNEST(state.stddev_w) AS stddev_w
            )
            SELECT state.count, state.count_errors,
            state.count_r, state.avg_r, 
            state.min_r, state.max_r, array_agg(sqrt(stddev_r/(count_r))),
            state.count_w, state.avg_w, 
            state.min_w, state.max_w, array_agg(sqrt(stddev_w/(count_w)))
            INTO result FROM arrays;

        return result;

    END IF;
END;
$$
LANGUAGE 'plpgsql';

-- Aggregate function declaration
CREATE AGGREGATE double_array_aggregate(att_array_devdouble)
(
    sfunc = fn_double_array_agg,
    stype = double_array_agg_state,
    combinefunc = fn_double_combine,
    finalfunc = fn_double_array_final
);

CREATE AGGREGATE float_array_aggregate(att_array_devfloat)
(
    sfunc = fn_float_array_agg,
    stype = float_array_agg_state,
    combinefunc = fn_float_combine,
    finalfunc = fn_float_array_final
);

CREATE AGGREGATE long_array_aggregate(att_array_devlong)
(
    sfunc = fn_long_array_agg,
    stype = long_array_agg_state,
    combinefunc = fn_long_combine,
    finalfunc = fn_long_array_final
);

CREATE AGGREGATE long64_array_aggregate(att_array_devlong64)
(
    sfunc = fn_long64_array_agg,
    stype = long64_array_agg_state,
    combinefunc = fn_long64_combine,
    finalfunc = fn_long64_array_final
);

CREATE AGGREGATE short_array_aggregate(att_array_devshort)
(
    sfunc = fn_short_array_agg,
    stype = short_array_agg_state,
    combinefunc = fn_short_combine,
    finalfunc = fn_short_array_final
);

CREATE AGGREGATE ulong_array_aggregate(att_array_devulong)
(
    sfunc = fn_ulong_array_agg,
    stype = ulong_array_agg_state,
    combinefunc = fn_ulong_combine,
    finalfunc = fn_ulong_array_final
);

CREATE AGGREGATE ulong64_array_aggregate(att_array_devulong64)
(
    sfunc = fn_ulong64_array_agg,
    stype = ulong64_array_agg_state,
    combinefunc = fn_ulong64_combine,
    finalfunc = fn_ulong64_array_final
);

CREATE AGGREGATE ushort_array_aggregate(att_array_devushort)
(
    sfunc = fn_ushort_array_agg,
    stype = ushort_array_agg_state,
    combinefunc = fn_ushort_combine,
    finalfunc = fn_ushort_array_final
);
