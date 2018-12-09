#!/bin/bash
# Setup Development Project
if [ "$#" -ne 1 ]; then
    echo "Usage:"
    echo "  $0 GUID"
    exit 1
fi

GUID=${1:-}
NAMESPACE_DEV="${GUID}-parks-dev"
NAMESPACE_PROD="${GUID}-parks-prod"
NAMESPACE_JENKINS="${GUID}-jenkins"
TEMPLATE="../templates/application-template.yml"
APP_IMAGESTREAMTAG="latest"

# Functions
deploy_application() {
  oc new-app -f ${TEMPLATE} \
  -p NAMESPACE=${NAMESPACE_DEV} \
  -p APP_NAME=${APP_NAME} \
  -p APP_IMAGESTREAMTAG=${APP_IMAGESTREAMTAG} \
  -p APP_DESCRIPTION="${APP_DESCRIPTION}" \
  -p BACKEND_SERVICE="${BACKEND_SERVICE}"
}

echo "Setting up Parks Development Environment in project ${NAMESPACE_DEV}"

# Code to set up the parks development project.

# To be Implemented by Student
# Grant permissions to the Jenkins service account
oc adm policy add-role-to-user edit system:serviceaccount:${NAMESPACE_JENKINS}:jenkins -n ${NAMESPACE_DEV}

# Create a MongoDB database
MONGODB_TEMPLATE="../templates/mongodb-persistent.yml"
MONGODB_USER="mongodb"
MONGODB_PASSWORD="mongodb"
MONGODB_DATABASE="parks"
MONGODB_ADMIN_PASSWORD="mongodbadmin"
MONGODB_HOST="mongodb"
MONGODB_PORT="27017"
MONGODB_CONFIGMAP="mongodb"

oc project ${NAMESPACE_DEV}
oc new-app -f ${MONGODB_TEMPLATE} \
-p MONGODB_USER=${MONGODB_USER} \
-p MONGODB_PASSWORD=${MONGODB_PASSWORD} \
-p MONGODB_DATABASE=${MONGODB_DATABASE} \
-p MONGODB_ADMIN_PASSWORD=${MONGODB_ADMIN_PASSWORD}

oc create cm ${CONFIGMAP_MONGODB} \
--from-literal=DB_HOST=${MONGODB_HOST} \
--from-literal=DB_PORT=${MONGODB_PORT} \
--from-literal=DB_USERNAME=${MONGODB_USER} \
--from-literal=DB_PASSWORD=${MONGODB_PASSWORD} \
--from-literal=DB_NAME=${MONGODB_DATABASE}

# Create binary build configurations for the pipelines to use for each microservice
# and ConfigMaps for configuration of the applications
# Set APPNAME to the following values—the grading pipeline checks for these exact strings:
# Set up placeholder deployment configurations for the three microservices
# Configure the deployment configurations using the ConfigMaps

# For MLBParks
CONTEXT_DIR=MLBParks
APP_NAME=$(echo ${CONTEXT_DIR} | tr '[:upper:]' '[:lower:]')
APP_DESCRIPTION="MLB Parks (Dev)"
BACKEND_SERVICE="parksmap-frontend"
deploy_application
oc set env dc/${APP_NAME} --from=configmap/${CONFIGMAP_MONGODB}
oc start-build ${APP_NAME}-pipeline -n ${NAMESPACE_JENKINS}

# For Nationalparks
CONTEXT_DIR=Nationalparks
APP_NAME=$(echo ${CONTEXT_DIR} | tr '[:upper:]' '[:lower:]')
APP_DESCRIPTION="National Parks (Dev)"
BACKEND_SERVICE="parksmap-frontend"
deploy_application
oc set env dc/${APP_NAME} --from=configmap/${CONFIGMAP_MONGODB}
oc start-build ${APP_NAME}-pipeline -n ${NAMESPACE_JENKINS}

# For ParksMap
CONTEXT_DIR=ParksMap
APP_NAME=$(echo ${CONTEXT_DIR} | tr '[:upper:]' '[:lower:]')
APP_DESCRIPTION="ParksMap (Dev)"
BACKEND_SERVICE=""
deploy_application
oc start-build ${APP_NAME}-pipeline -n ${NAMESPACE_JENKINS}
