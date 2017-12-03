#!/bin/bash
#Setup some basic variables
DOCKER_IMAGE_NAME=http_mod_proxy
LOCAL_PORT=7003
REMOTE_PORT=80
CONTAINER_NAME=httpd_proxy7003

# Docker RUN HELP:
# -d, --detach                         Run container in background and print container ID

# Run the container detached
docker run --rm --name $CONTAINER_NAME --detach -p $LOCAL_PORT:$REMOTE_PORT $DOCKER_IMAGE_NAME


# Connect to a running container to explore it:
# docker exec -it httpd_proxy7003 /bin/bash


# COPY the APACHE2 HTTP FOLDER:
# docker cp httpd_proxy7003:/usr/local/apache2 ./
# upload modified file:
# docker cp apache2/conf/extra/99sono-proxy.conf httpd_proxy7003:/usr/local/apache2/conf/extra/99sono-proxy.conf

# Interactively run the container and explore the file system
#docker rm $CONTAINER_NAME
#docker run --rm --name $CONTAINER_NAME -i -p $LOCAL_PORT:$REMOTE_PORT $DOCKER_IMAGE_NAME /bin/bash


# mount a folder on the target machine:
# -v "/home/nunogdem/Dev/Docker/docker-build/docker-java7:/var/www/html"