@ECHO OFF
call "%~dp0\0_setCoreEnvVariables.bat" %*

docker cp src/wildfly-installer-0.0.1-SNAPSHOT-package.zip %CONTAINER_NAME%:/tmp/wildfly-installer-0.0.1-SNAPSHOT-package.zip