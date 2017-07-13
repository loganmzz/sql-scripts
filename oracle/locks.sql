SELECT * FROM DBA_BLOCKERS ;
SELECT * FROM DBA_DDL_LOCKS WHERE session_id='<session>';
SELECT * FROM DBA_LOCK_INTERNAL WHERE session_id='<session>';
SELECT * FROM DBA_LOCKS WHERE session_id='<session>';
select * from DBA_WAITERS;
select * from DBA_LOCKS where session_id in (select sid from v$session where username='<username>');
