@ECHO OFF
call "%~dp0\0_setCoreEnvVariables.bat" %*
docker exec -it %CONTAINER_NAME% /bin/bash