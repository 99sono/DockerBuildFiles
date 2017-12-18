@ECHO OFF
call "%~dp0\0_setCoreEnvVariables.bat" %*
docker build -t %IMAGE_NAME% .
