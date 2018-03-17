@ECHO OFF
call "%~dp0\0_setCoreEnvVariables.bat" %*

REM docker exec -it %CONTAINER_NAME%  sqlplus SYS/oracle AS SYSDBA <<< "select 1 from dual; \n select 2 from dual;"
SET DB_USER_NAME=%1

ECHO GOING TO CREATE USER %DB_USER_NAME%
docker exec -it %CONTAINER_NAME%  /bin/bash -c "echo -e 'DROP USER %DB_USER_NAME% CASCADE;' | sqlplus SYS/oracle as SYSDBA"

