@ECHO OFF
call "%~dp0\0_setCoreEnvVariables.bat" %*

REM docker exec -it %CONTAINER_NAME%  sqlplus SYS/oracle AS SYSDBA <<< "select 1 from dual; \n select 2 from dual;"
SET DB_USER_NAME=%1

docker exec -i %CONTAINER_NAME%  /bin/bash -c "echo -e 'select username, profile from DBA_USERS where username IS NOT NULL;\n' | sqlplus SYS/oracle as SYSDBA"

