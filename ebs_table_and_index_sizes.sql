WITH tab_size AS 
   (SELECT owner, table_name, SUM(total_bytes) total_bytes, SUM(tab_bytes) tab_bytes, SUM(ind_bytes) ind_bytes, 
           SUM(lob_bytes) lob_bytes, SUM(lobind_bytes) lobind_bytes 
    FROM 
       (SELECT owner, segment_name table_name, bytes total_bytes, bytes tab_bytes, 0 ind_bytes, 0 lob_bytes, 0 lobind_bytes  
        FROM dba_segments  
        WHERE segment_type IN ('TABLE', 'TABLE PARTITION', 'TABLE SUBPARTITION')
        UNION ALL  
        SELECT i.table_owner owner, i.table_name, s.bytes total_bytes, 0 tab_bytes, s.bytes ind_bytes, 0 lob_bytes, 0 lobind_bytes  
        FROM dba_indexes i, dba_segments s  
        WHERE s.segment_name = i.index_name  
        AND   s.owner = i.owner  
        AND   s.segment_type IN ('INDEX', 'INDEX PARTITION', 'INDEX SUBPARTITION')  
        UNION ALL  
        SELECT l.owner, l.table_name, s.bytes total_bytes, 0 tab_bytes, 0 ind_bytes, s.bytes lob_bytes, 0 lobind_bytes  
        FROM dba_lobs l, dba_segments s  
        WHERE s.segment_name = l.segment_name  
        AND   s.owner = l.owner  
        AND   s.segment_type IN ('LOBSEGMENT', 'LOB PARTITION')  
        UNION ALL  
        SELECT l.owner, l.table_name, s.bytes total_bytes, 0 tab_bytes, 0 ind_bytes, 0 lob_bytes, s.bytes lobind_bytes  
        FROM dba_lobs l, dba_segments s  
        WHERE s.segment_name = l.index_name  
        AND   s.owner = l.owner  
        AND   s.segment_type = 'LOBINDEX') 
    GROUP BY owner, table_name)
SELECT fa.application_name, 
       t.owner,
       t.table_name,
       ROUND(t.total_bytes/(1024*1024),0) Total_MB,
       ROUND(t.tab_bytes/(1024*1024),0) Table_MB,
       ROUND(t.ind_bytes/(1024*1024),0) Indexes_MB,
       ROUND(t.lob_bytes/(1024*1024),0) LOB_MB,
       ROUND(t.lobind_bytes/(1024*1024),0) LOBIndexes_MB,
       fou.oracle_id,
       'EBS App' EBS_App,
       ft.description
FROM tab_size t,
     fnd_oracle_userid fou,
     fnd_product_installations fpi,
     fnd_tables ft,
     fnd_application_tl fa 
WHERE fou.oracle_username = t.owner  
AND fpi.oracle_id = fou.oracle_id  
AND ft.table_name = t.table_name  
AND fpi.application_id = ft.application_id  
AND fa.application_id = ft.application_id  
AND fa.language = 'US'  
AND t.total_bytes IS NOT NULL  
AND t.total_bytes >= 104857600 
UNION ALL  
--Not EBS Apps  
SELECT fa.application_name,
       t.owner,
       t.table_name,
       ROUND(t.total_bytes/(1024*1024),0) Total_MB,
       ROUND(t.tab_bytes/(1024*1024),0) Table_MB,
       ROUND(t.ind_bytes/(1024*1024),0) Indexes_MB,
       ROUND(t.lob_bytes/(1024*1024),0) LOB_MB,
       ROUND(t.lobind_bytes/(1024*1024),0) LOBIndexes_MB,
       fou.oracle_id,
       'Not EBS App' EBS_App,
       ft.description  
FROM tab_size t,
     fnd_oracle_userid fou,
     fnd_product_installations fpi,
     fnd_tables ft,
     fnd_application_tl fa  
WHERE fou.oracle_username (+) = t.owner  
AND fpi.oracle_id (+) = fou.oracle_id  
AND ft.table_name (+) = t.table_name  
AND fpi.application_id (+) = ft.application_id  
AND fa.application_id (+) = ft.application_id  
AND fa.language (+) = 'US'  
AND t.owner != 'SYS'  
AND ft.application_id IS NULL  
AND t.total_bytes IS NOT NULL  
AND t.total_bytes >= 104857600
ORDER BY 4 DESC;
