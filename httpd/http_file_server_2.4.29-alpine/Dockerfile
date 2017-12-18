FROM httpd:2.4.29-alpine

# Update the operating system
# enable apache modules related to mod proxy
# NOTE: We also add curl since it might be useful to login with a bash file to the machine
# and test doing downloads directly from the machine itself
RUN \
    echo "Step: (1) Fix .vimrc arrow navigation" && \
    echo "set nocompatbile" > ~/.vimrc &&\    
    echo "Step: (2) Update the Alpine Linux Operating system" && \
    apk update && \   
    echo "Step: (3) Add apache2 modules - not so relevant for file server" && \
    apk add apache2 && \
    apk add apache2-proxy && \
    echo "Step: (4) Install CURL (optional but we like it)" && \
    apk add curl && \
    echo "Running apk package updates finished."

# We now could copy over our src/conf directory into the apache server. 
# Instead of doing this we will mount it and re place /usr/local/apache2/conf with our configuration
# this will avoid that we need to invoke docker build just because we change a small line of configuration

# NOTE: Main files tuned in the src/conf
# 1. Httpd.conf where we enable the vhosts.conf include statement
# 2. conf/extra/extra-vhosts.conf where we define a small virtual host that allows everyone to download files from the system.
