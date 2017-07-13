select
--       s.sid
      --,s.serial#
      --,s.username
      --,s.machine
      --,s.status
      --,s.lockwait
--      ,
      t.used_ublk
      ,t.used_urec
      ,t.start_time
      ,round((ts.block_size * t.used_ublk)/1024/1024, 3) "UNDO (MB)"
from v$transaction t
--inner join v$session s on t.addr = s.taddr
inner join v$parameter p on p.name='undo_tablespace'
inner join dba_tablespaces ts on ts.tablespace_name=p.value
 ;
 
select
  begin_time, end_time, undoblks, round(undoblks*8/1024/1024,3), activeblks,round(activeblks*8/1024/1024,3), s.parsing_schema_name, s.sql_text
from v$undostat u inner join v$sql s on s.sql_id=u.maxqueryid
order by activeblks desc
;

select
--       s.sid
      --,s.serial#
      --,s.username
      --,s.machine
      --,s.status
      --,s.lockwait
--      ,
      t.used_ublk
      ,t.used_urec
      ,t.start_time
      ,round((ts.block_size * t.used_ublk)/1024/1024, 3) "UNDO (MB)"
from v$transaction t
--inner join v$session s on t.addr = s.taddr
inner join v$parameter p on p.name='undo_tablespace'
inner join dba_tablespaces ts on ts.tablespace_name=p.value
 ;
 
select
  begin_time, end_time, undoblks, round(undoblks*8/1024/1024,3), activeblks,round(activeblks*8/1024/1024,3), s.parsing_schema_name, s.sql_text
from v$undostat u inner join v$sql s on s.sql_id=u.maxqueryid
order by activeblks desc
;

select owner, tablespace_name, status, round(sum(bytes)/1024/1024/1024,3) from dba_undo_extents group by owner, tablespace_name, status;

select * from v$undostat;
