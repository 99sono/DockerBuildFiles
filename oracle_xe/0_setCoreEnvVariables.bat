@ECHO OFF

REM We add a dot at the end because dp0 ends in a trailing slash. 
REM and code is more readable if we add \ building paths later on.
set SCRIPT_PATH=%~dp0.


SET IMAGE_NAME=httpd_fileserver
SET LOCAL_PORT=1521
SET REMOTE_PORT=1521
SET CONTAINER_NAME=infallible_thompson
SET HOST_NAME=%CONTAINER_NAME%

