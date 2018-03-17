@ECHO OFF
call "%~dp0\0_setCoreEnvVariables.bat" %*

REM docker exec -it %CONTAINER_NAME%  sqlplus SYS/oracle AS SYSDBA <<< "select 1 from dual; \n select 2 from dual;"
docker exec -it %CONTAINER_NAME%  /bin/bash -c "echo select 1 FROM dual && echo -e 'SELECT 2 FROM DUAL;\n SELECT 3 FROM DUAL;' | sqlplus SYS/oracle as SYSDBA"