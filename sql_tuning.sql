DECLARE
    v_sql_tune_task_id VARCHAR2(100);
BEGIN
    v_sql_tune_task_id := dbms_sqltune.create_tuning_task(sql_id => '&sql_id', scope => dbms_sqltune.scope_comprehensive, time_limit =>
    1000, task_name => 'tuning_task_&sql_id', description => 'Tuning task for the SQL statement with the ID:&sql_id from the cursor cache');

    dbms_output.put_line('v_sql_tune_task_id: ' || v_sql_tune_task_id);
END;
/

BEGIN dbms_sqltune.Execute_tuning_task (task_name => 'tuning_task_&sql_id'); END;
/
select dbms_sqltune.report_tuning_task('tuning_task_&sql_id') from dual;  

SELECT sql_id, status, sql_text FROM v$sql_monitor;

SELECT DBMS_SQLTUNE.report_sql_monitor(sql_id => '&sql_id', type => 'TEXT') AS report FROM dual;
