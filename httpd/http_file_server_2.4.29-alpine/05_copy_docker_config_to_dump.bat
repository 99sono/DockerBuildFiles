@ECHO OFF
call "%~dp0\0_setCoreEnvVariables.bat" %*

docker cp %CONTAINER_NAME%:/usr/local/apache2/conf .\dump\