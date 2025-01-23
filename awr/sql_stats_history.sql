select 
sql_id,
plan_hash_value, sql_profile,
END_INTERVAL_TIME,
executions_delta,
round(ELAPSED_TIME_DELTA/(nonzeroexecutions*1000)/1000,2) "Elapsed Average s",
CPU_TIME_DELTA/(nonzeroexecutions*1000) "CPU Average ms",
IOWAIT_DELTA/(nonzeroexecutions*1000) "IO Average ms",
CLWAIT_DELTA/(nonzeroexecutions*1000) "Cluster Average ms",
APWAIT_DELTA/(nonzeroexecutions*1000) "Application Average ms",
CCWAIT_DELTA/(nonzeroexecutions*1000) "Concurrency Average ms",
BUFFER_GETS_DELTA/nonzeroexecutions "Average buffer gets",
DISK_READS_DELTA/nonzeroexecutions "Average disk reads",
trunc(PHYSICAL_WRITE_BYTES_DELTA/(1024*1024*nonzeroexecutions)) "Average disk write megabytes",
ROWS_PROCESSED_DELTA/nonzeroexecutions "Average rows processed"
from
(select 
ss.snap_id,
ss.sql_id,
ss.plan_hash_value,sql_profile,
sn.END_INTERVAL_TIME,
ss.executions_delta,
case ss.executions_delta when 0 then 1 else ss.executions_delta end nonzeroexecutions,
ELAPSED_TIME_DELTA,
CPU_TIME_DELTA,
IOWAIT_DELTA,
CLWAIT_DELTA,
APWAIT_DELTA,
CCWAIT_DELTA,
BUFFER_GETS_DELTA,
DISK_READS_DELTA,
PHYSICAL_WRITE_BYTES_DELTA,
ROWS_PROCESSED_DELTA
from DBA_HIST_SQLSTAT ss,DBA_HIST_SNAPSHOT sn
where ss.sql_id = '&sql_id'
and ss.snap_id=sn.snap_id
and ss.INSTANCE_NUMBER=sn.INSTANCE_NUMBER)
where ELAPSED_TIME_DELTA > 0
order by snap_id,sql_id;
