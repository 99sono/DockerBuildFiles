FROM httpd:2.4.29-alpine

# Update the operating system
# enable apache modules related to mod proxy
# REFERENCES:
#   https://www.digitalocean.com/community/tutorials/how-to-use-apache-as-a-reverse-proxy-with-mod_proxy-on-ubuntu-16-04
# https://httpd.apache.org/docs/2.4/mod/mod_proxy.html
# mod_proxy_http, which adds support for proxying HTTP connections.
RUN \    
    apk update && \   
    apk add apache2 && \
    apk add apache2-proxy && \    
    echo "Running apk package updates finished."

# We Now want to Override the ApacheHttpD configuration
# NOTE: To do it on a created container we would do something such as:
# docker cp apache2/conf/extra/99sono-proxy.conf httpd_proxy7003:/usr/local/apache2/conf/extra/99sono-proxy.conf
# docker cp apache2/conf/httpd.conf httpd_proxy7003:/usr/local/apache2/conf/httpd.conf       
COPY src/httpd.conf /usr/local/apache2/conf/httpd.conf  
COPY src/extra/99sono-proxy.conf /usr/local/apache2/conf/extra/99sono-proxy.conf  
