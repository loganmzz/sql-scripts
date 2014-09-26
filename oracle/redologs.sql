-- Variables
---- Level: Oracle system table prefix (DBA, ALL, USER)
DEFINE LEVEL=DBA
DEFINE USER=USER

-- Table list
SELECT * FROM "V$LOG";               -- Redo log group list
SELECT * FROM "V$LOGFILE";           -- Redo log file  list
SELECT * FROM "V$LOG_HISTORY"        -- Redo log switch history
  ORDER BY "FIRST_TIME" DESC;

-- Views

---- Redo logs
SELECT
  "RD"."GROUP#", "LF"."MEMBER", ROUND("RD".BYTES/1024/1024,2) "SIZE (MB)", "RD"."STATUS", "RD"."ARCHIVED", "RD"."FIRST_TIME", "RD"."NEXT_TIME", "LF"."TYPE"
FROM
  "V$LOG" "RD"
  JOIN "V$LOGFILE" "LF" ON
    "LF"."GROUP#"="RD"."GROUP#"
ORDER BY
  "RD"."GROUP#", "LF"."MEMBER"
;

-- Actions
-- Add redo log group
ALTER DATABASE ADD LOGFILE GROUP 1 ('<PATH>') SIZE 100M;
-- Passes 'active' to 'inactive'
ALTER SYSTEM CHECKPOINT GLOBAL;
-- Switch redo log
ALTER SYSTEM SWITCH LOGFILE;
