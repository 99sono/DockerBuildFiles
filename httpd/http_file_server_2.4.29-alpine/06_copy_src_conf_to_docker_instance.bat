@ECHO OFF
call "%~dp0\0_setCoreEnvVariables.bat" %*

docker cp .\src\conf %CONTAINER_NAME%:/usr/local/apache2/conf 