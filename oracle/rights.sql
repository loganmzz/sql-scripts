-- Variables
---- Level: Oracle system table prefix (DBA, ALL, USER)
DEFINE LEVEL=DBA
DEFINE USER=USER

-- Table list
SELECT * FROM "&LEVEL._USERS";       -- User list
SELECT * FROM "&LEVEL._ROLES";       -- Role list
SELECT * FROM "&LEVEL._ROLE_PRIVS";  -- Role privilegies
SELECT * FROM "&LEVEL._SYS_PRIVS";   -- System priviligies granted to user/roles
SELECT * FROM "&LEVEL._TAB_PRIVS";   -- Object priviligies granted to user/roles

-- Views

---- Role relationships
SELECT
  "R"."ROLE", "RP"."GRANTED_ROLE"
  ,SYS_CONNECT_BY_PATH("R"."ROLE", '/') "HIERARCHY"
FROM 
    "&LEVEL._ROLES" "R"
    LEFT JOIN "&LEVEL._ROLE_PRIVS" "RP" ON
      "R"."ROLE"="RP"."GRANTEE"
CONNECT BY PRIOR "R"."ROLE" = "RP"."GRANTED_ROLE"
;

---- User roles
SELECT
  "RP"."GRANTEE", "RP"."GRANTED_ROLE", "RP"."ADMIN_OPTION"
FROM "&LEVEL._ROLE_PRIVS" "RP"
START WITH "RP"."GRANTEE" = &USER.
CONNECT BY PRIOR "RP"."GRANTEE" = "RP"."GRANTED_ROLE"
ORDER BY "RP"."GRANTEE"
;

---- Transitive system priviligies
SELECT * FROM "&LEVEL._SYS_PRIVS" WHERE "GRANTEE" IN (
  SELECT &USER. FROM DUAL UNION ALL
  -- ref:User roles
  SELECT "RP"."GRANTED_ROLE"
  FROM "&LEVEL._ROLE_PRIVS" "RP"
  START WITH "RP"."GRANTEE" = &USER.
  CONNECT BY PRIOR "RP"."GRANTEE" = "RP"."GRANTED_ROLE"
)
;

---- Transitive object priviligies
SELECT * FROM "&LEVEL._TAB_PRIVS" WHERE "GRANTEE" IN (
  SELECT &USER. FROM DUAL UNION ALL
  -- ref:User roles
  SELECT "RP"."GRANTED_ROLE"
  FROM "&LEVEL._ROLE_PRIVS" "RP"
  START WITH "RP"."GRANTEE" = &USER.
  CONNECT BY PRIOR "RP"."GRANTEE" = "RP"."GRANTED_ROLE"
)
;

---- Tablespace priviligies
SELECT * FROM DBA_TS_QUOTAS WHERE USERNAME=&USER.;
