#!/bin/bash
#Setup some basic variables
DOCKER_IMAGE_NAME=httpd_fileserver
LOCAL_PORT=7003
REMOTE_PORT=80
CONTAINER_NAME=httpd_fileserver_7003
CURRENT_DIRECTORY=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )

# Docker RUN HELP:
# -d, --detach                         Run container in background and print container ID

# Run the container detached
echo "Going to start doccer container and mount the drive: $CURRENT_DIRECTORY"
echo docker run --rm -v "$CURRENT_DIRECTORY/src/www:/usr/local/apache2/htdocs" --name $CONTAINER_NAME --detach -p $LOCAL_PORT:$REMOTE_PORT $DOCKER_IMAGE_NAME
