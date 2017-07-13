---- SPACE MANAGEMENT
-- Total spaces
SELECT 'SIZE (GB)' "LABEL",  ROUND(SUM(FILES.BYTES)/1024/1024/1024,3) "VALUE" FROM DBA_DATA_FILES FILES
UNION ALL
SELECT 'FREE (GB)' "LABEL",  ROUND(SUM(FREE.BYTES)/1024/1024/1024,3) "VALUE" FROM DBA_FREE_SPACE FREE
UNION ALL
SELECT 'FREEABLE (GB)' "LABEL",  ROUND(SUM(FILES.BYTES-BLOCKS.MAXBLOCK*TB.BLOCK_SIZE)/1024/1024/1024,3) "VALUE"
FROM
  DBA_TABLESPACES TB
  JOIN DBA_DATA_FILES FILES ON
    FILES.TABLESPACE_NAME=TB.TABLESPACE_NAME
  JOIN (SELECT FILE_ID, MAX(BLOCK_ID + BLOCKS) "MAXBLOCK" FROM DBA_EXTENTS GROUP BY FILE_ID) BLOCKS ON
    BLOCKS.FILE_ID=FILES.FILE_ID
;

-- Reclaim freespace
SET SERVEROUTPUT ON;
BEGIN
  FOR c IN (
    SELECT B.FILE_NAME, A.MINBLOCK*C.BLOCK_SIZE "MINSIZE"
    FROM
      DBA_TABLESPACES C
        JOIN
      DBA_DATA_FILES B
        ON B.TABLESPACE_NAME=C.TABLESPACE_NAME
        JOIN
      (SELECT FILE_ID, MAX(BLOCK_ID + BLOCKS) "MINBLOCK" FROM DBA_EXTENTS GROUP BY FILE_ID) A
        ON A.FILE_ID=B.FILE_ID
    WHERE
      C.TABLESPACE_NAME NOT IN ('SYSTEM', 'SYSAUX', 'USERS') AND
      C.CONTENTS='PERMANENT' AND
      B.BLOCKS > A.MINBLOCK
  ) LOOP
  BEGIN
    DBMS_OUTPUT.PUT_LINE('ALTER DATABASE DATAFILE '''||c.FILE_NAME||''' RESIZE '||(c.MINSIZE/1024/1024+1)||'M');
    EXECUTE IMMEDIATE 'ALTER DATABASE DATAFILE '''||c.FILE_NAME||''' RESIZE '||c.MINSIZE;
  EXCEPTION
    WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE('Can''t resize: '||C.FILE_NAME);
      DBMS_OUTPUT.PUT_LINE(SQLERRM);
  END;
  END LOOP;
END;
/

-- Consumers stats
SELECT
  owner, round(sum(bytes)/1024/1024) "SPACES (MB)"
FROM dba_extents
GROUP BY owner
ORDER BY sum(bytes) desc;
SELECT
  ts.tablespace_name,
  regexp_replace(df.file_name, '.*/', '') FILE_NAME,
  df.FILE_ID,
  round(df.bytes/1024/1024,2) "SIZE (MB)",
  round(NVL(fr.bytes,0)/1024/1024,2) "FREE (MB)",
  round((NVL(ex.BLOCKS,0)*ts.block_size)/1024/1024,2) "MIN (MB)",
  round((NVL(ex.BLOCKS,0)*ts.block_size-NVL(ex.BYTES,0))/1024/1024,2) "LOST (MB)"
FROM
  dba_tablespaces ts
  JOIN dba_data_files df ON
   df.tablespace_name=ts.tablespace_name
  LEFT JOIN (SELECT file_id, MAX(block_id+BLOCKS) BLOCKS, SUM(BYTES) BYTES FROM dba_extents GROUP BY file_id) ex ON
    ex.file_id=df.file_id
  LEFT JOIN (SELECT file_id, SUM(bytes) BYTES FROM dba_free_space GROUP BY file_id) fr ON
    fr.file_id=df.file_id
ORDER BY
  ts.tablespace_name,
  df.file_id
;


-- Most cleanable
SELECT
  TB.TABLESPACE_NAME,
  FILES.FILE_NAME,
  ROUND(FILES.BYTES/1024/1024,3) "SIZE (MB)",
  ROUND(FREE.BYTES/1024/1024,3) "FREE (MB)",
  ROUND((FILES.BYTES-FREE.BYTES)/1024/1024,3) "USED (MB)",
  ROUND((BLOCKS.MAXBLOCK*TB.BLOCK_SIZE)/1024/1024,3) "MIN (MB)",
  ROUND((FILES.BYTES-BLOCKS.MAXBLOCK*TB.BLOCK_SIZE)/1024/1024,3) "FREEABLE (MB)"
FROM
  DBA_TABLESPACES TB
  JOIN
  DBA_DATA_FILES FILES ON
    FILES.TABLESPACE_NAME=TB.TABLESPACE_NAME
  LEFT JOIN
  (SELECT FILE_ID, SUM(BYTES) "BYTES" FROM DBA_FREE_SPACE FREE GROUP BY FILE_ID) FREE ON
    FREE.FILE_ID=FILES.FILE_ID
  LEFT JOIN
    (SELECT FILE_ID, MAX(BLOCK_ID + BLOCKS) "MAXBLOCK" FROM DBA_EXTENTS GROUP BY FILE_ID) BLOCKS ON
      BLOCKS.FILE_ID=FILES.FILE_ID
--WHERE
--  FILES.TABLESPACE_NAME like '%XXX%'
ORDER BY
  (FILES.BYTES-BLOCKS.MAXBLOCK*TB.BLOCK_SIZE) DESC NULLS LAST
--FREE.BYTES DESC NULLS LAST
--FILES.TABLESPACE_NAME, FILES.FILE_NAME
;

-- Empty
---- Schema
SELECT * FROM dba_users
WHERE username IN (
  SELECT username  FROM dba_users
  MINUS
  SELECT owner FROM all_objects
)
ORDER BY user_id
;
---- Data files
SELECT tablespace_name, file_name, file_id, round(bytes/1024/1024,2) bytes FROM dba_data_files WHERE tablespace_name IN (
  SELECT tablespace_name FROM dba_tablespaces
  MINUS
  SELECT tablespace_name FROM dba_extents
)
ORDER BY tablespace_name
;
SELECT tablespace_name, file_name, file_id, round(bytes/1024/1024,2) bytes FROM dba_data_files WHERE tablespace_name IN (
 (
   select tablespace_name from dba_tablespaces
   MINUS
   select tablespace_name from dba_ts_quotas
 )
 MINUS
   select tablespace_name from dba_segments
);
---- Tablespace
select
  t.tablespace_name,
  q.username,
  q.bytes,
  q.max_bytes,
  round(e.bytes/1024/1024,3) MB,
  e.tablespace_names
from
 (
  select tablespace_name from dba_tablespaces
  minus
  select tablespace_name from dba_extents
 ) t
 left join dba_ts_quotas q on
   q.tablespace_name = t.tablespace_name
 left join (
   select owner, listagg(tablespace_name) within group(order by tablespace_name) tablespace_names, sum(bytes) bytes
   from (
     select owner, tablespace_name, sum(bytes) bytes from dba_extents group by owner, tablespace_name
   )
   group by owner) e on
   e.owner=q.username
order by u.last_logon_date desc NULLS FIRST, q.username NULLS FIRST, t.tablespace_name;

-- Compact data
DECLARE
  v_tablespace_like VARCHAR2(100) := '<tablespace_name_like>';
BEGIN
  FOR c IN (SELECT * FROM dba_tablespaces WHERE tablespace_name NOT IN ('SYSTEM', 'SYSAUX', 'USERS', 'TEMP', 'UNDOTBS02') AND tablespace_name like v_tablespace_like) loop
    EXECUTE IMMEDIATE 'ALTER TABLESPACE "'ADOC_WEB_INT_TSDATA||c.tablespace_name||'" COALESCE';
  END loop;
  FOR c IN (SELECT * FROM dba_indexes WHERE INDEX_TYPE<>'LOB' AND TEMPORARY='N' AND tablespace_name not in ('SYSTEM', 'SYSAUX', 'USERS', 'TEMP', 'UNDOTBS02') AND tablespace_name like v_tablespace_like) loop
    EXECUTE IMMEDIATE 'alter index "'||c.owner||'"."'||c.index_name||'" rebuild';
    EXECUTE IMMEDIATE 'ANALYZE INDEX "'||c.owner||'"."'||c.index_name||'" COMPUTE STATISTICS';
    EXECUTE IMMEDIATE 'ANALYZE INDEX "'||c.owner||'"."'||c.index_name||'" VALIDATE STRUCTURE';
  END loop;
  FOR c IN (SELECT distinct owner, segment_name FROM dba_segments WHERE segment_type like 'TABLE%' and tablespace_name LIKE v_tablespace_like) loop
    EXECUTE IMMEDIATE 'alter table "'||c.owner||'"."'||c.segment_name||'" enable row movement';
    EXECUTE IMMEDIATE 'alter table "'||c.owner||'"."'||c.segment_name||'" shrink space cascade';
    EXECUTE IMMEDIATE 'alter table "'||c.owner||'"."'||c.segment_name||'" disable row movement';
  END loop;
END;
/

--Shrink lob
BEGIN
  FOR c IN (SELECT DISTINCT TABLESPACE_NAME, OWNER, TABLE_NAME, COLUMN_NAME FROM ALL_LOBS WHERE TABLESPACE_NAME LIKE '<tablespace>') LOOP
    EXECUTE IMMEDIATE 'ALTER TABLE "'||c.OWNER||'"."'||c.TABLE_NAME||'" MODIFY LOB("'||c.COLUMN_NAME||'") (SHRINK SPACE)';
  END LOOP;
END;
/
-- Purge recyclebin
BEGIN
  FOR C IN (SELECT OWNER, TABLESPACE_NAME FROM DBA_SEGMENTS WHERE OWNER LIKE '<username>') LOOP
    EXECUTE IMMEDIATE 'PURGE TABLESPACE '||C.TABLESPACE_NAME||' USER '||C.OWNER;
  END LOOP;
END;
/
