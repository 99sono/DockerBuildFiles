# Docker Build to create an apache HTTPD proxy

# HOST NODEJS:
1. Start with node serve --isable-host-check
This will be available under:
http://localhost:4200/
E.g 
http://localhost:4200/assets/LoginSuccessResponse.2.json


# Springboot:
E.g. 
http://localhost:7001/rest/login

# Httpd Proxy:
1. Launch the docker container with
docker run --rm --name $CONTAINER_NAME --detach -p $LOCAL_PORT:$REMOTE_PORT $DOCKER_IMAGE_NAME

2. Visit the Proxied URLS, e.g.
http://localhost:7003/ willd redirect to -> http://localhost:4200/

http://localhost:7003/springboot/rest/login -> http://localhost:7001/rest/login


# NOTES:
When running mod proxy to work-around the cross origin request problem, it is better of all applications
have an app-context root, instead of allowing them to use the ROOT context of the container.
In this means that ideally, neither springboot nor nodejs should allow requests to run from / and always force
requests to come from some app context root.

Configuration of applications will eventually be tuned to reflect the point said above, and the configuration of the sources for the docker build changed.
