select * from v$sql;

select * from v$sqlarea;

select * from v$sql_plan;


---- SESSION MANAGEMENT
select username, osuser, machine, status, program, type,
event#, event,
p1text, p1, p1raw,
p2text, p2, p2raw,
p3text, p3, p3raw
from v$session
where
  event# not in (345)
order by username;


select S.USERNAME, s.sid, s.osuser, t.sql_id, sql_text
from v$sqltext_with_newlines t,V$SESSION s
where t.address =s.sql_address
and t.hash_value = s.sql_hash_value
and s.status = 'ACTIVE'
and s.username <> 'SYSTEM'
order by s.sid,t.piece
;

SELECT sid, to_char(start_time,'hh24:mi:ss') stime, 
message,( sofar/totalwork)* 100 percent 
FROM v$session_longops
WHERE sofar/totalwork < 1;

select s.username,s.sid,s.serial#,s.last_call_et/60 mins_running,q.sql_text from v$session s 
join v$sqltext_with_newlines q
on s.sql_address = q.address
 where status='ACTIVE'
and type <>'BACKGROUND'
and last_call_et> 60
order by sid,serial#,q.piece
;


SELECT * FROM DBA_ADVISOR_RECOMMENDATIONS;
select * from DBA_ADVISOR_FINDINGS;

select tablespace_name, segment_name, segment_type, partition_name,
recommendations, c1 FROM
TABLE(dbms_space.asa_recommendations('FALSE', 'FALSE', 'FALSE'));


-- Setup SQL*Plus output
set pagesize 0
set feedback off
set recsep off
set colsep ";"
set linesize 32767

-- Extract
spool output.csv
select ....;
spool off
