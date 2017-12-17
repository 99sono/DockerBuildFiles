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
