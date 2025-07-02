--Currently set to CPU
--Change to elapsed or execution as needed
select details.*,sqltext.sql_text from 
(
select stat.sql_id, rank() over (order by (max(stat.cpu_time_total/stat.executions_total)) desc) cpu_rank,
rank() over (order by (max(stat.elapsed_time_total/stat.executions_total)) desc) elapsed_rank,
SUM(stat.executions_totaL) execution_TOTAL
from
 dba_hist_sqlstat stat inner join dba_hist_snapshot snap on snap.snap_id=stat.snap_id and stat.executions_total >0
--where
-- snap.begin_interval_time between sysdate-7
--and
-- sysdate
group by
 stat.sql_id
 ) details inner join dba_hist_sqltext sqltext on details.sql_id=sqltext.sql_id
 where cpu_rank <=100 
-- where elapsed_rank<=100;
-- where execution_rank<=100
 order by cpu_rank;
 --order by elapsed_rank;
 --order by execution_rank;
