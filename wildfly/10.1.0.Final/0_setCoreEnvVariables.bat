@ECHO OFF

REM We add a dot at the end because dp0 ends in a trailing slash. 
REM and code is more readable if we add \ building paths later on.
set SCRIPT_PATH=%~dp0.


SET WILDFLY_IMAGE_NAME=wildfly_base
SET WILDFLY_IMAGE_VERSION=10.1.0.Final
SET HTTP_LOCAL_PORT=8080
SET HTTP_REMOTE_PORT=8080
SET HTTP_LOCAL_ADMIN_PORT=9990
SET HTTP_REMOTE_ADMIN_PORT=9990


SET CONTAINER_NAME=wildfly.8080
SET HOST_NAME=%CONTAINER_NAME%
SET APACHE_HTTPD_FILE_SER_HOST_NAME=httpd.fileserver
