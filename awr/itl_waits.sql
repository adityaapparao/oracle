-- Use this script to find index contention to increase initrans
-- Monday to Friday
-- 9am to 5pm 
-- last 31 days

with snap as (select snap_id,dbid,instance_number from dba_hist_snapshot 
where to_char(begin_interval_time,'D') in (2,3,4,5,6)
and to_number(to_char(begin_interval_time,'HH24')) between 9 and 17
and begin_interval_time > sysdate-31)
  SELECT /*+ noparallel */ sso.owner,
         sso.object_name,
         sso.subobject_name,
         sso.object_type,
--         SUM (ss.table_scans_delta),
         sum(ss.ITL_WAITS_DELTA)
    FROM dba_hist_seg_stat ss, dba_hist_seg_stat_obj sso, snap sn
   WHERE     ss.dbid = sso.dbid
         AND ss.ts# = sso.ts#
         AND ss.obj# = sso.obj#
         AND ss.dataobj# = sso.dataobj#
         AND ss.dbid = sn.dbid
         AND ss.instance_number = sn.instance_number
         AND ss.snap_id = sn.snap_id
GROUP BY sso.owner,
         sso.object_name,
         sso.subobject_name,
         sso.object_type
  HAVING SUM (ss.ITL_WAITS_DELTA) > 0
ORDER BY SUM (ss.ITL_WAITS_DELTA) DESC;
