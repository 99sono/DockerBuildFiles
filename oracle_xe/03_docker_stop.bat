@ECHO OFF
call "%~dp0\0_setCoreEnvVariables.bat" %*
docker stop %CONTAINER_NAME% 