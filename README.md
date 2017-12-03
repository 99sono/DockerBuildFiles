# Docker Builds

## httpd
Docker builds starting from apache httpd.
Mod-proxy docker build is used to setup a docker apache httpd that will act as a proxy for a NODE-JS and SpintBoot application.

### Node js disable host validation
In node JS we want to start the server with:
Disable HOST Validation in Server.js webkit:
ng serve --disable-host-check

REASON:
If we do not this the and we are proxying via the docker apache httpd, it well end up happening that apache forwards requests with host = docker.for.mac.localhost and these are ignored.
