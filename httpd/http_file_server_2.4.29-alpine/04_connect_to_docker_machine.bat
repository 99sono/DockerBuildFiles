@echo off

SET CONTAINER_NAME=httpd_fileserver_7003
docker exec -it %CONTAINER_NAME% /bin/bash