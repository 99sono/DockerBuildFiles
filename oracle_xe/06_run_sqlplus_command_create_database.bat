@ECHO OFF
call "%~dp0\0_setCoreEnvVariables.bat" %*

REM docker exec -i %CONTAINER_NAME%  sqlplus SYS/oracle AS SYSDBA <<< "select 1 from dual; \n select 2 from dual;"
SET DB_USER_NAME=%1

ECHO GOING TO CREATE USER %DB_USER_NAME%
docker exec -i %CONTAINER_NAME%  /bin/bash -c "echo -e 'CREATE USER %DB_USER_NAME% IDENTIFIED BY %DB_USER_NAME% DEFAULT TABLESPACE USERS;' | sqlplus SYS/oracle as SYSDBA"

ECHO GOING TO ADD PERMISSIONS
docker exec -i %CONTAINER_NAME%  /bin/bash -c "echo -e 'grant CREATE SESSION, ALTER SESSION, CREATE DATABASE LINK, CREATE MATERIALIZED VIEW, CREATE PROCEDURE, CREATE PUBLIC SYNONYM, CREATE ROLE, CREATE SEQUENCE, CREATE SYNONYM, CREATE TABLE, CREATE TRIGGER, CREATE TYPE, CREATE VIEW, UNLIMITED TABLESPACE TO %DB_USER_NAME%;' | sqlplus SYS/oracle as SYSDBA"





REM alter user %DB_USER_NAME% default tablespace users;
REM alter user %DB_USER_NAME% identified by %DB_USER_NAME% account unlock;
REM GRANT SELECT ON sys.dba_pending_transactions TO %DB_USER_NAME%;
REM GRANT SELECT ON sys.pending_trans$ TO %DB_USER_NAME%;
REM GRANT SELECT ON sys.dba_2pc_pending TO %DB_USER_NAME%;
REM GRANT EXECUTE ON sys.dbms_xa TO %DB_USER_NAME%;
REM GRANT FORCE ANY TRANSACTION TO %DB_USER_NAME%;
ECHO GOING TO ADD ADDITIONAl PERMISSIONS
REM docker exec -i %CONTAINER_NAME%  /bin/bash -c "echo -e 'alter user %DB_USER_NAME% default tablespace users; alter user %DB_USER_NAME% identified by %DB_USER_NAME% account unlock; GRANT SELECT ON sys.dba_pending_transactions TO %DB_USER_NAME%; GRANT SELECT ON sys.pending_trans$ TO %DB_USER_NAME%; GRANT SELECT ON sys.dba_2pc_pending TO %DB_USER_NAME%; GRANT EXECUTE ON sys.dbms_xa TO %DB_USER_NAME%; GRANT FORCE ANY TRANSACTION TO %DB_USER_NAME%;' | sqlplus SYS/oracle as SYSDBA"
docker exec -i %CONTAINER_NAME%  /bin/bash -c "echo -e 'alter user %DB_USER_NAME% default tablespace users;\n alter user %DB_USER_NAME% identified by %DB_USER_NAME% account unlock;\n GRANT SELECT ON sys.dba_pending_transactions TO %DB_USER_NAME%;\n GRANT SELECT ON sys.pending_trans$ TO %DB_USER_NAME%;\n GRANT SELECT ON sys.dba_2pc_pending TO %DB_USER_NAME%;\n GRANT EXECUTE ON sys.dbms_xa TO %DB_USER_NAME%;\n GRANT FORCE ANY TRANSACTION TO %DB_USER_NAME%;\n' | sqlplus SYS/oracle as SYSDBA"
