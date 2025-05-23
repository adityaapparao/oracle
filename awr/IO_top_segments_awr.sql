/* For PDB */
/* Adjust dates on line 22 and 23 */
with BASIS_INFO AS
( SELECT /*+ MATERIALIZE */
    DECODE(DBID, -1, OWN_DBID, DBID) DBID,
    DECODE(INSTANCE_NUMBER, -1, USERENV('INSTANCE'), INSTANCE_NUMBER) INSTANCE_NUMBER,
    BEGIN_DATE,
    END_DATE,
    TO_TIMESTAMP(TO_CHAR(BEGIN_DATE, 'dd.mm.yyyy hh24:mi:ss'), 
      'dd.mm.yyyy hh24:mi:ss') BEGIN_TIME,
    TO_TIMESTAMP(TO_CHAR(END_DATE, 'dd.mm.yyyy hh24:mi:ss'), 
      'dd.mm.yyyy hh24:mi:ss') END_TIME,
    BEGIN_SNAP_ID,    
    END_SNAP_ID,
    SEGMENT_TYPE,
    SEGMENT_NAME,
    NUM_RECORDS_GLOBAL,
    NON_RAC_STATS,
    RAC_STATS
  FROM
  ( SELECT
      -1 DBID,
      -1 INSTANCE_NUMBER,        /* -1 for current instance, -2 for all instances */
      TO_DATE('01.01.2025 11:55:00', 'dd.mm.yyyy hh24:mi:ss') BEGIN_DATE,
      TO_DATE('31.12.2025 18:05:00', 'dd.mm.yyyy hh24:mi:ss') END_DATE,
      -1 BEGIN_SNAP_ID,   /* explicit SNAP_IDs sometimes required for ASH partition pruning */
      -1 END_SNAP_ID,
      '%' SEGMENT_TYPE,
      '%' SEGMENT_NAME,
      -1 NUM_RECORDS_GLOBAL,
      'X' NON_RAC_STATS,
      'X' RAC_STATS
    FROM
      DUAL
  ),
  ( select dbid OWN_DBID, con_id, name from v$pdbs ) --SELECT DBID OWN_DBID FROM V$DATABASE )
), SNAPSHOTS AS
( SELECT 
    HSS.DBID,
    HSS.INSTANCE_NUMBER,
    MIN(HSS.SNAP_ID) BEGIN_SNAP_ID,
    MIN(HSS.BEGIN_INTERVAL_TIME) BEGIN_TIME,
    MAX(HSS.SNAP_ID) END_SNAP_ID,
    MAX(HSS.END_INTERVAL_TIME) END_TIME,
    SUM(TO_CHAR(HSS.END_INTERVAL_TIME, 'SSSSS') -
      TO_CHAR(HSS.BEGIN_INTERVAL_TIME, 'SSSSS') +
      86400 * (TO_CHAR(HSS.END_INTERVAL_TIME, 'J') - 
               TO_CHAR(HSS.BEGIN_INTERVAL_TIME, 'J'))) SECONDS
  FROM 
    DBA_HIST_SNAPSHOT HSS,
    BASIS_INFO BI
  WHERE
    HSS.DBID = BI.DBID AND
    ( BI.INSTANCE_NUMBER = -2 OR
      HSS.INSTANCE_NUMBER = BI.INSTANCE_NUMBER 
    ) AND
    HSS.END_INTERVAL_TIME <= BI.END_TIME AND
    HSS.BEGIN_INTERVAL_TIME >= BI.BEGIN_TIME
  GROUP BY
    HSS.DBID,
    HSS.INSTANCE_NUMBER
), pre_final as (
 SELECT
    S.INSTANCE_NUMBER,
    DECODE(NVL(O.owner, SSO.owner), 
      '** UNAVAILABLE **', NVL(O2.owner, S.OBJ# || '/' || S.DATAOBJ#),
      NVL(O.owner, NVL(SSO.owner, S.OBJ# || '/' || S.DATAOBJ#))) SEGMENT_owner,
    DECODE(NVL(O.OBJECT_NAME, SSO.OBJECT_NAME), 
      '** UNAVAILABLE **', NVL(O2.OBJECT_NAME, S.OBJ# || '/' || S.DATAOBJ#),
      NVL(O.OBJECT_NAME, NVL(SSO.OBJECT_NAME, S.OBJ# || '/' || S.DATAOBJ#))) SEGMENT_NAME,
    MIN(NVL(O.OBJECT_TYPE, SSO.OBJECT_TYPE)) SEG_TYPE,
    SUM(S.LOGICAL_READS_DELTA) LOGICAL_READS,
    SUM(S.PHYSICAL_READS_DELTA) PHYSICAL_READS,
    SUM(S.DB_BLOCK_CHANGES_DELTA) DB_BLOCK_CHANGES,
    SUM(S.PHYSICAL_WRITES_DELTA) PHYSICAL_WRITES,
    SUM(S.PHYSICAL_READS_DIRECT_DELTA) PHYSICAL_READS_DIRECT,
    SUM(S.PHYSICAL_WRITES_DIRECT_DELTA) PHYSICAL_WRITES_DIRECT,
    SUM(S.BUFFER_BUSY_WAITS_DELTA) BUFFER_BUSY_WAITS,
    SUM(S.ITL_WAITS_DELTA) ITL_WAITS,
    SUM(S.ROW_LOCK_WAITS_DELTA) ROW_LOCK_WAITS,
    SUM(S.TABLE_SCANS_DELTA) SEGMENT_SCANS,
    SUM(S.SPACE_USED_DELTA) / 1024 / 1024 SPACE_USED_DELTA_MB,
    SUM(S.SPACE_ALLOCATED_DELTA) / 1024 / 1024 SPACE_ALLOC_DELTA_MB,
    SUM(S.GC_CR_BLOCKS_SERVED_DELTA) GC_CR_BLOCKS_SERVED_DELTA,
    SUM(S.GC_CU_BLOCKS_SERVED_DELTA) GC_CU_BLOCKS_SERVED_DELTA,
    SUM(S.GC_CR_BLOCKS_RECEIVED_DELTA) GC_CR_BLOCKS_RECEIVED_DELTA,
    SUM(S.GC_CU_BLOCKS_RECEIVED_DELTA) GC_CU_BLOCKS_RECEIVED_DELTA,
    SUM(S.GC_BUFFER_BUSY_DELTA) GC_BUFFER_BUSY_DELTA
    ,max(begin_snap_id) begin_snap_id, max(end_snap_id) end_snap_id, min(BEGIN_TIME) BEGIN_TIME, max(end_time) end_time
  FROM
    SNAPSHOTS SS,
    DBA_HIST_SEG_STAT S,
    DBA_OBJECTS O,
    DBA_HIST_SEG_STAT_OBJ SSO,
    DBA_OBJECTS O2
  WHERE
    S.DBID = SS.DBID AND
    S.INSTANCE_NUMBER = SS.INSTANCE_NUMBER AND
    S.SNAP_ID BETWEEN SS.BEGIN_SNAP_ID AND SS.END_SNAP_ID AND
    S.OBJ# = O.OBJECT_ID (+) AND
    S.DATAOBJ# = O.DATA_OBJECT_ID (+) AND
    S.OBJ# = SSO.OBJ# (+) AND
    S.DATAOBJ# = SSO.DATAOBJ# (+) AND
    S.OBJ# = O2.OBJECT_ID (+) 
  GROUP BY
      DECODE(NVL(O.owner, SSO.owner), 
      '** UNAVAILABLE **', NVL(O2.owner, S.OBJ# || '/' || S.DATAOBJ#),
      NVL(O.owner, NVL(SSO.owner, S.OBJ# || '/' || S.DATAOBJ#))),
    DECODE(NVL(O.OBJECT_NAME, SSO.OBJECT_NAME), 
      '** UNAVAILABLE **', NVL(O2.OBJECT_NAME, S.OBJ# || '/' || S.DATAOBJ#),
      NVL(O.OBJECT_NAME, NVL(SSO.OBJECT_NAME, S.OBJ# || '/' || S.DATAOBJ#))),
    S.INSTANCE_NUMBER)
select * from pre_final
where seg_type is not null and seg_type != 'UNDEFINED';
