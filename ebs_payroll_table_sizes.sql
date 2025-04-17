-- table list from 	Tips for Improving Payroll Performance (Doc ID 1079475.6)
with v1 as ( select table_name, last_analyzed table_analyzed, num_rows
from dba_tables
where owner = 'HR'
and table_name in ('PAY_ACTION_CONTEXTS',
'PAY_ACTION_INFORMATION',
'PAY_ASSIGNMENT_ACTIONS',
'PAY_ASSIGNMENT_LATEST_BALANCES',
'PAY_BALANCE_CONTEXT_VALUES',
'PAY_BALANCE_VALIDATION',
'PAY_BATCH_LINES',
'PAY_COSTS',
'PAY_ELEMENT_ENTRIES_F',
'PAY_ELEMENT_ENTRY_VALUES_F',
'PAY_ENTRY_PROCESS_DETAILS',
'PAY_GL_INTERFACE',
'PAY_INPUT_VALUES_F',
'PAY_LATEST_BALANCES',
'PAY_PAYROLL_ACTIONS',
'PAY_PERSON_LATEST_BALANCES',
'PAY_POPULATION_RANGES',
'PAY_PRE_PAYMENTS',
'PAY_PROCESS_EVENTS',
'PAY_PURGE_ROLLUP_BALANCES',
'PAY_RECORDED_REQUESTS',
'PAY_RETRO_ENTRIES',
'PAY_RUN_BALANCES',
'PAY_RUN_RESULT_VALUES',
'PAY_RUN_RESULTS',
'PAY_TEMP_OBJECT_ACTIONS',
'PAY_US_RPT_TOTAL',
'PER_ALL_ASSIGNMENTS_F',
'PER_ALL_PEOPLE_F',
'PER_ORGANIZATION_LIST',
'PER_PERIODS_OF_SERVICE',
'PER_PERSON_LIST',
'PER_POSITION_LIST')),
v2 as (select i.table_name, min(i.last_analyzed) index_min_analyzed, max(i.last_analyzed) index_max_analyzed
from dba_indexes i, v1
where v1.table_name = i.table_name
group by i.table_name),
v3 as (select segment_name, round(sum(bytes)/1024/1024) table_size_mb
from dba_segments s, v1
where s.segment_name = v1.table_name
group by segment_name)
select v1.table_name, v3.table_size_mb,v1.num_rows,v1.table_analyzed, v2.index_min_analyzed,v2.index_max_analyzed
from v1, v2, v3
where v1.table_name = v2.table_name
and v1.table_name = v3.segment_name
order by 2 desc;
