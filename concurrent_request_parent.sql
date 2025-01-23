SELECT
/*+ ORDERED USE_NL(x fcr fcp fcptl)*/
SUBSTR(fcr.request_id,1,10) "Request ID"
, SUBSTR(parent_request_id,1,10) "Parent ID"
, SUBSTR(fcptl.user_concurrent_program_name,1,40) "Program Name"
, FCPRC.NODE_NAME "DB Node" -- this is node that processed the request
, FCR.OUTFILE_NODE_NAME "Output file Node" -- this is the node where the output files were processed
, fcr.phase_code
, fcr.status_code
, SUBSTR(TO_CHAR(fcr.actual_start_date,'DD-MON HH24:MI:SS'),1,16) "Start Time"
, SUBSTR(TO_CHAR(fcr.actual_completion_date, 'DD-MON HH24:MI:SS'),1,16) "End Time"
, TO_CHAR((fcr.actual_completion_date - fcr.actual_start_date)*1440,'9999.00') "Elapsed"
, SUBSTR(fcr.oracle_process_id,1,10) "Trace ID"
, FCR.COMPLETION_TEXT
, FCR.LOGFILE_NAME  LOGFILE
, FCR.OUTFILE_NAME  OUTFILE
,FEC.value || '/' || FCPRC.PLSQL_LOG  TMPLOG
, FCR.ARGUMENT_TEXT "Parameters"
FROM
(SELECT
/*+ index (fcr1 fnd_concurrent_requests_n3) */
fcr1.request_id
FROM
apps.fnd_concurrent_requests fcr1
WHERE
1 =1
START WITH fcr1.request_id =
(SELECT -- walk up the request family tree to the root
MIN(fcr2.request_id) root
FROM apps.fnd_concurrent_requests fcr2
CONNECT BY fcr2.request_id = prior fcr2.parent_request_id
start with FCR2.REQUEST_ID = &Request_ID -- amp child_request_id
) -- decending from the root, select all of the requests in the family
CONNECT BY PRIOR fcr1.request_id = fcr1.parent_request_id) x
, apps.fnd_concurrent_requests fcr
, apps.fnd_concurrent_programs fcp
, APPS.FND_CONCURRENT_PROGRAMS_TL FCPTL
, APPS.FND_ENV_CONTEXT FEC
, APPS.FND_CONCURRENT_PROCESSES FCPRC
WHERE fcr.request_id = x.request_id
AND fcr.concurrent_program_id = fcp.concurrent_program_id
AND fcr.program_application_id = fcp.application_id
AND fcp.application_id = fcptl.application_id
AND fcp.concurrent_program_id = fcptl.concurrent_program_id
and FCPTL.LANGUAGE = 'US'
and FEC.VARIABLE_NAME = 'APPLPTMP'
and FCR.CONTROLLING_MANAGER = FCPRC.CONCURRENT_PROCESS_ID
and FCPRC.CONCURRENT_PROCESS_ID = FEC.CONCURRENT_PROCESS_ID
ORDER BY 1;
