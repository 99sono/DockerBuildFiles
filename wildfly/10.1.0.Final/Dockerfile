# Use latest jboss/base-jdk:7 image as the base
# Explore docker with bash:
# On Powershell: docker exec -it 54c5717735f9 "/bin/bash"
FROM jboss/base-jdk:8


# Set the WILDFLY_VERSION env variable
ENV WILDFLY_VERSION 10.1.0.Final

ENV JBOSS_HOME /opt/jboss/wildfly/widlfly_10_1_0_Final
ENV WILDFLY_HOME /opt/jboss/wildfly/widlfly_10_1_0_Final

# Coordinates to download the installer
# This would be the URL if we could do a docker-link during build - but we cannot
# Therefore instead we will use a URL from localhost that redirects to the correct docker machine
ENV URL_TO_HTTP_FILE_SERVER http://httpd.fileserver/files
# ENV URL_TO_HTTP_FILE_SERVER http://localhost:7003/files
ENV WILDFLY_INSTALLER_ZIP wildfly-installer-0.0.1-SNAPSHOT-package.zip

# curl -O http://httpd.fileserver/files/wildfly-installer-0.0.1-SNAPSHOT-package.zip

# Add the WildFly distribution to /opt, and make wildfly the owner of the extracted tar content
# Make sure the distribution is available from a well-known place
RUN \
    echo "Step: (1) Fix .vimrc arrow navigation" && \
    echo "set nocompatbile" > ~/.vimrc &&\
    echo "Step: (2) Go into the tmp folder, and download the widfly installer. " && \
    mkdir /tmp/dump && cd /tmp/dump &&\
    curl -O $URL_TO_HTTP_FILE_SERVER/$WILDFLY_INSTALLER_ZIP && \
    echo "Step: (3) Calculte the MD5SUM of the file. The md5sum should be: 598622d64771f917a9e26d660f04d103.  " && \
    md5sum /tmp/dump/$WILDFLY_INSTALLER_ZIP && \    
    echo "Please check the md5sum result. - this should be automated  " && \
    echo "Step: (4) Unzip the installer within the dump folder. Note Apache needed setting EnableSendFile on, otherwise data was corrupted." && \
    unzip wildfly-installer-0.0.1-SNAPSHOT-package.zip &&\
    echo "Step: (5) Install wildfly into WILDFLY_HOME " && \
    sh /tmp/dump/wildfly-installer/3_run_installWildfly.sh && \
    echo "Step (5) Cleanup space in the tmp folder " && \
    cd /tmp && rm -rf /tmp/dump && \
    echo "Step (6) Prepare an empty user_projects folder within our wildfly installation. This where we would normally create domains" && \
    mkdir -p $WILDFLY_HOME/user_projects/domains && \
    echo "Step (7) Wildfly installation completed. Check $WILDFLY_HOME "

# Ensure signals are forwarded to the JVM process correctly for graceful shutdown
ENV LAUNCH_JBOSS_IN_BACKGROUND true

# Expose the ports we're interested in
# (a) Expose the HTTP port
EXPOSE 8080
# (b) Expose the HTTPS port
EXPOSE 8443
# (c) HTTP-Management Port: 
EXPOSE 9990
# (D) HTTPS-Management Port: 
EXPOSE 9993
# (c) REMOTE EJB - CORBA port
# But we actually do not need this because we use the
# http-remoting-connector
# EXPOSE 4447

# Set the default command to run on boot
# This will boot WildFly in the standalone mode and bind to all interface
# CMD ["/opt/jboss/wildfly/bin/standalone.sh", "-b", "0.0.0.0"]

USER root

# Install some network utilities that are missing from this centos 7 distribution
RUN  \
    yum install -y iproute && \
    yum install -y telnet