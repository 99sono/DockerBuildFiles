
@ECHO OFF
call "%~dp0\0_setCoreEnvVariables.bat" %*

REM docker run -d -p 8080:8080 -p 1521:1521 sath89/oracle-12c
REM Run with data on host and reuse it:

REM docker run -d -p 8080:8080 -p 1521:1521 -v /my/oracle/data:/u01/app/oracle sath89/oracle-12c
REM Run with Custom DBCA_TOTAL_MEMORY (in Mb):
REM docker run  -d -p 8585:8080 -p 1521:1521 -v C:/dev/branches/docker_images/oracle_xe/oracle_data -e DBCA_TOTAL_MEMORY=1024 sath89/oracle-xe-11g

REM docker run -d -p 8080:8080 -p 1521:1521 -v /my/oracle/data:/u01/app/oracle -e DBCA_TOTAL_MEMORY=1024 sath89/oracle-12c

REM docker pull sath89/oracle-12c
REM docker pull sath89/oracle-xe-11g

ECHO Going to start container:  %CONTAINER_NAME%
docker start  %CONTAINER_NAME%



