select /*+ noparallel */ inst_id, sid, event, last_call_et, program, sql_id, prev_sql_id,client_identifier, program, machine, osuser,pq_status,FINAL_BLOCKING_SESSION, action
from gv$session
where status = 'ACTIVE'
and type = 'USER'
and event not like 'Stream%'
and osuser != 'aditya.apparao1'
order by last_call_et desc;
