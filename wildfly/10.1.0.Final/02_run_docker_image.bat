@ECHO OFF
call "%~dp0\0_setCoreEnvVariables.bat" %*

REM (a) Run The Wildfly Image - do not configure any particular host name to access db
REM docker run --rm --hostname=%HOST_NAME%  --name %CONTAINER_NAME%  -p %HTTP_LOCAL_PORT%:%HTTP_REMOTE_PORT% -p %HTTP_LOCAL_ADMIN_PORT%:%HTTP_REMOTE_ADMIN_PORT%  -it %WILDFLY_IMAGE_NAME%:%WILDFLY_IMAGE_VERSION% /bin/bash

REM (b) Run The Wildfly Image - configure postgres.db hostname
SET POSTGRES_SERVER_IP=192.168.1.192
SET POSTGRES_SERVER_HOST_NAME=postgres.db
docker run --rm  --add-host="%POSTGRES_SERVER_HOST_NAME%:%POSTGRES_SERVER_IP%" --hostname=%HOST_NAME%  --name %CONTAINER_NAME%  -p %HTTP_LOCAL_PORT%:%HTTP_REMOTE_PORT% -p %HTTP_LOCAL_ADMIN_PORT%:%HTTP_REMOTE_ADMIN_PORT%  -it %WILDFLY_IMAGE_NAME%:%WILDFLY_IMAGE_VERSION% /bin/bash


REM NOTE:
REM At this point we have a wildfly installed with custom patches and modules (e.g. logging appenders, etc...)
REM If we want to check that we can startup the server we need to invoke:
REM [jboss@wildfly bin]$ sh standalone.sh "-b" "0.0.0.0" "-bmanagement" "0.0.0.0"
REM REFERENCES:
REM https://hub.docker.com/r/jboss/wildfly/

REM POSTGRES RUNNING ON HOST 
REM NOTE:
REM TO be able to connect to a postgres database running on the hos then:
REM File postgressql.conf
REM listen_addresses = '*'	
REM file pg_hba.conf
REM # Allow all to connect to the datbaase
REM host all all 0.0.0.0/0 password
REM host    all             all              ::/0                            password
