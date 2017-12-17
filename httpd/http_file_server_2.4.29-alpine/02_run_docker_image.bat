@echo off
REM Setup some basic variables
set SCRIPT_PATH=%~dp0.
SET DOCKER_IMAGE_NAME=httpd_fileserver
SET LOCAL_PORT=7003
SET REMOTE_PORT=80
SET CONTAINER_NAME=httpd_fileserver_7003
REM CURRENT_DIRECTORY=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

REM # Docker RUN HELP:
REM # -d, --detach                         Run container in background and print container ID

REM # Run the container detached
echo "Going to start doccer container and mount the drive: %SCRIPT_PATH%"
REM docker run --rm  --name %CONTAINER_NAME% --detach -p %LOCAL_PORT%:%REMOTE_PORT% %DOCKER_IMAGE_NAME%
docker run --rm -v "%SCRIPT_PATH%\src\www:/usr/local/apache2/htdocs" --name %CONTAINER_NAME% --detach -p %LOCAL_PORT%:%REMOTE_PORT% %DOCKER_IMAGE_NAME%