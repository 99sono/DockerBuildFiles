# Docker Build to Create an Apache Server to Quickly host files

# INSTRUCTIONS:
Put the desired files in the files src/www/files directory.
Put the docker image to run using the 02 script to run the docker image.
The src/www/files will be mounted on the apache httpd 
/usr/local/apache2/htdocs

# MOTIVATION:
The primary motivation for this docker build is to help us save disk space when building arbitrary docker images.
It is quite anoying that the build COPY command takes up space by creating a staging docker machine.
So removing these files from the docker image is pointless since space is swalled by the copy command.
If the files are small and they should continue to exist, we do not care.
But if the file we are copying to the machine is something like a ZIP files installer, then
we want to remove it and save space.
In these situations the easies is to run a local apache server that can serve the desired files, and download it with CURL and remove it afteards.

#Do not use underscores as part of hostname:
When running a docker image to act as a file server, is this docker image will be contacted by other docker containers (e.g. wildfly docker build to download an installer), make sure that the hostname given to the httpd file server does not have any underscores.
The following image illustrates that the docker instance name has been renamed from httpd_fileserver_7003 to simply httpd.fileserver.
Likewise, the hostname.

PS C:\dev\branches\docker_images\apache\file-server> docker ps
CONTAINER ID        IMAGE               COMMAND             CREATED             STATUS              PORTS                    NAMES
4a3b9b392505        httpd_fileserver    "/bin/bash"         5 minutes ago       Up 5 minutes        0.0.0.0:7003->80/tcp     httpd.fileserver

Failing to uphold this rule will lead to CURL get requests that apache httpd will refuse with error 400 - and no good justification to reason to refuse the request.

# FILES CHANGES IN RELATION TO ORIGINAL APACHE HTTPD:
1. httpd.conf
Here we enable  the line: 
Include conf/extra/httpd-vhosts.conf

We also enable the line: 
'''
EnableSendfile on
'''
Without this, apprently, the sending of large zip files (e.g. 100 MB or more) leads to data corruption.


2. httpd-vhosts.conf
Here we add a simple virtual host that allows easy access to all files in the /usr/local/apache2/htdocs

# Serving Files to another container during build
In order to solve the problem of being able to apache httpd (docker) to serve files to a second
container during, build what we do is:
1. First we create shared network for the http file server and the new docker machine:
docker network create docker-build

2. We run the docker file server with the script: 02_run_docker_image_network_install.bat
The docker machine will be running in this network.

3. We can trigger the docker build of the new machine with something like
'''
docker build --network docker-build -t %WILDFLY_IMAGE_NAME%:%WILDFLY_IMAGE_VERSION% .
'''

4. During docker build, this machine should be able to access http://hppd.fileserver:80/files/FileToDownload.zip

