@ECHO OFF
call "%~dp0\0_setCoreEnvVariables.bat" %*


REM RUN: jboss/base-jdk:8  without linking access to any other docker container
docker run --rm --hostname=%HOST_NAME%  --name %CONTAINER_NAME%  -p %LOCAL_PORT%:%REMOTE_PORT%  -it jboss/base-jdk:8 /bin/bash

REM RUN: jboss/base-jdk:8  with acess to httpd.fileserver hostname (e.g. expriment building manually)
REM docker run --rm --hostname=%HOST_NAME% --link=%APACHE_HTTPD_FILE_SER_HOST_NAME% --name %CONTAINER_NAME%  -p %LOCAL_PORT%:%REMOTE_PORT%  -it jboss/base-jdk:8 /bin/bash
