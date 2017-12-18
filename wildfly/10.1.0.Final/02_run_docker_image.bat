@ECHO OFF
call "%~dp0\0_setCoreEnvVariables.bat" %*

docker run --rm --hostname=%HOST_NAME%  --name %CONTAINER_NAME%  -p %HTTP_LOCAL_PORT%:%HTTP_REMOTE_PORT% -p %HTTP_LOCAL_ADMIN_PORT%:%HTTP_REMOTE_ADMIN_PORT%  -it %WILDFLY_IMAGE_NAME%:%WILDFLY_IMAGE_VERSION% /bin/bash

REM NOTE:
REM At this point we have a wildfly installed with custom patches and modules (e.g. logging appenders, etc...)
REM If we want to check that we can startup the server we need to invoke:
REM [jboss@wildfly bin]$ sh standalone.sh "-b" "0.0.0.0" "-bmanagement" "0.0.0.0"
REM REFERENCES:
REM https://hub.docker.com/r/jboss/wildfly/

