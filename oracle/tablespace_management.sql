-- Copy tablespace
DECLARE
  --Actions
  v_action_create_tablespace VARCHAR2(1) := 'N';
  v_action_move_table_data VARCHAR2(1) := 'N';
  v_action_move_index VARCHAR2(1) := 'N';
  v_action_move_lob VARCHAR2(1) := 'N';
  v_action_resize_tablespace VARCHAR2(1) := 'N';
  v_action_drop_tablespace VARCHAR2(1) := 'N';
  -- Concerned tablespace to compact
  v_tab_space VARCHAR2(255) := 'D750_PRIMES_TSDATA';
  v_new_tab_space VARCHAR2(255) := v_tab_space||'_BIS';
BEGIN
  IF v_action_create_tablespace = 'Y' THEN
    DECLARE
      -- Data File
      v_data_file VARCHAR2(255);
      -- Size = Current size + 10%
      v_size NUMBER(12);
      -- Extend Size = Current size * 5%
      v_extend_size NUMBER(12);
    BEGIN
      -- Computes values
      SELECT MAX(file_name), SUM(bytes) INTO v_data_file, v_size FROM dba_data_files WHERE tablespace_name=v_tab_space;
      SELECT v_size-SUM(bytes) INTO v_size FROM dba_free_space WHERE tablespace_name=v_tab_space;
      ---- Data file
      v_data_file :=
        -- Get prefix
        SUBSTR(v_data_file,1,INSTR(v_data_file,'.', -1)-1)||
        -- Adds suffix
        '_bis'||
        -- Adds extension
        SUBSTR(v_data_file,INSTR(v_data_file,'.', -1));
      
      ---- Size
      v_size := CEIL(v_size * 1.1);
      v_extend_size := CEIL((v_size * 5) / 100);
      --Create tablespace
      EXECUTE IMMEDIATE 'CREATE TABLESPACE "'||v_new_tab_space||'" DATAFILE '''||v_data_file||''' SIZE '||v_size||' AUTOEXTEND ON NEXT '||v_extend_size;
    END;
    --Grant users
    FOR c IN (SELECT DISTINCT OWNER FROM dba_segments WHERE tablespace_name=v_tab_space) LOOP
      EXECUTE IMMEDIATE 'alter user "'||c.owner||'" quota unlimited on "'||v_new_tab_space||'"';
    END LOOP;
  END IF;
  
  --Move table data
  IF v_action_move_table_data = 'Y' THEN
    FOR c IN (SELECT * FROM all_tables WHERE tablespace_name=v_tab_space) LOOP
      EXECUTE IMMEDIATE 'alter table "'||c.owner||'"."'||c.table_name||'" move tablespace "'||v_new_tab_space||'"';
    END LOOP;
  END IF;
  --Move indexes
  IF v_action_move_index = 'Y' THEN
    FOR c IN (SELECT * FROM all_indexes WHERE tablespace_name=v_tab_space) LOOP
      EXECUTE IMMEDIATE 'alter index "'||c.owner||'"."'||c.index_name||'" rebuild tablespace "'||v_new_tab_space||'" compute statistics';
    END LOOP;
  END IF;
  --Move LOBs
  IF v_action_move_lob = 'Y' THEN
    FOR c IN (SELECT * FROM all_lobs WHERE tablespace_name=v_tab_space) LOOP
      EXECUTE IMMEDIATE 'alter table "'||c.owner||'"."'||c.table_name||'" MOVE LOB("'||c.COLUMN_NAME||'") STORE AS (TABLESPACE "'||v_new_tab_space||'")';
    END LOOP;
  END IF;

  IF v_action_resize_tablespace = 'Y' THEN
    FOR c IN (SELECT * FROM dba_data_files WHERE tablespace_name=v_tab_space) LOOP
      EXECUTE IMMEDIATE 'ALTER DATABASE DATAFILE '''||c.file_name||''' RESIZE 10M';
    END LOOP;
  END IF;

  IF v_action_drop_tablespace = 'Y' THEN
      EXECUTE IMMEDIATE 'DROP TABLESPACE "'||v_tab_space||'" INCLUDING CONTENTS AND DATAFILES';
      EXECUTE IMMEDIATE 'ALTER TABLESPACE "'||v_new_tab_space||'" RENAME TO "' ||v_tab_space||'"';
  END IF;
END;
/

-- Tablspace clean up
ALTER DATABASE DATAFILE XXXXXXX RESIZE 10M
ALTER TABLESPACE XXXXXXXXXXXXXX OFFLINE
DROP TABLESPACE XXXXXXXXXXX INCLUDING CONTENTS AND DATAFILES;
CREATE TABLESPACE "xxx_TSDATA" DATAFILE '/home/oracle/u01/oradata/<database>/xxx_ts_data.dbf' SIZE 5G AUTOEXTEND ON NEXT 512M MAXSIZE 10G
