@ECHO OFF
call "%~dp0\0_setCoreEnvVariables.bat" %*

REM # Run the container detached
echo "Going to start doccer container and mount the drive: %SCRIPT_PATH%"

REM INFO:
REM PATH TO WHERE APACHE 2 IS INSTALLED:
REM /usr/local/apache2
REM THE COMMAND USED TO TRIGGER APACHE HTTPD IS:
REM /usr/local/bin/httpd-foreground

REM START APACHE HTTPD AS FILE SERVER:
REM (A) BASIC STARTUP - WITHOUT CONTROLLING HOSTNAME:
REM docker run --rm  --name %CONTAINER_NAME% --detach -p %LOCAL_PORT%:%REMOTE_PORT% %IMAGE_NAME%
REM (B) Configure host name and directories to mount
docker run --rm --hostname=%CONTAINER_NAME% -v "%SCRIPT_PATH%\src\conf:/usr/local/apache2/conf" -v "%SCRIPT_PATH%\src\www:/usr/local/apache2/htdocs" --name %CONTAINER_NAME% --detach -p %LOCAL_PORT%:%REMOTE_PORT% %IMAGE_NAME%

REM ALTERNATIVE: start apache httpd with bash
REM docker run --rm -it --hostname=%CONTAINER_NAME% -v "%SCRIPT_PATH%\src\www:/usr/local/apache2/htdocs" --name %CONTAINER_NAME%  -p %LOCAL_PORT%:%REMOTE_PORT% %IMAGE_NAME% /bin/bash
REM (a) Make sure that VI is usable by adding the nocompatbile
REM # echo "set nocompatbile" > ~/.vimrc
REM (b) Go to the folder where the launcher of apache httpd is found
REM bash-4.3# cd /usr/local/bin
REM (c) Launch the apache httpd process
REM bash-4.3# ./httpd-foreground
