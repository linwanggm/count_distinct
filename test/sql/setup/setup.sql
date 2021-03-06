\set ECHO none

BEGIN;

-- install the module
\i sql/count_distinct--2.0.0.sql

-- create and analyze tables (parallel plans work only on real tables, not on SRFs)
create table test_data_1_20 as select generate_series(1,20) x;
create table test_data_1_25 as select generate_series(1,25) x;
create table test_data_0_50 as select generate_series(0,50) x;
create table test_data_1_50 as select generate_series(1,50) x;
create table test_data_1_1000 as select generate_series(1,1000) x;
create table test_data_0_1000 as select generate_series(0,1000) x;
analyze test_data_1_20;
analyze test_data_1_25;
analyze test_data_0_50;
analyze test_data_1_50;
analyze test_data_1_1000;
analyze test_data_0_1000;

-- if server supports parallel execution, force it and check if it works
do $$
declare
    t text;
begin
    if (
        select true
        from pg_attribute
        where attrelid = 'pg_catalog.pg_aggregate'::regclass
          and attname = 'aggcombinefn'
    ) then
        perform set_config('min_parallel_relation_size', '0', true),
                set_config('parallel_setup_cost', '0', true),
                set_config('parallel_tuple_cost', '0', true),
                set_config('max_parallel_workers_per_gather', '22', true);
        
        for t in explain select count(*) from test_data_1_20 loop
            if t like '%Gather%' then
                -- Here we can see parallel execution is on
                return;
            end if;
        end loop;
        raise 'Looks like parallel aggregation is off';
    end if;
end;
$$;

\set ECHO all
