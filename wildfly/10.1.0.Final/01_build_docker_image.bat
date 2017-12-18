@ECHO OFF
call "%~dp0\0_setCoreEnvVariables.bat" %*

REM docker build -t %WILDFLY_IMAGE_NAME%:%WILDFLY_IMAGE_VERSION% .
REM Run docker build using a commond network to the machine hosting the files
docker build --network docker-build -t %WILDFLY_IMAGE_NAME%:%WILDFLY_IMAGE_VERSION% .
 
