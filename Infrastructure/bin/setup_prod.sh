#!/bin/bash
# Setup Production Project (initial active services: Green)
if [ "$#" -ne 1 ]; then
    echo "Usage:"
    echo "  $0 GUID"
    exit 1
fi

GUID=${1:-}

# Load variables and fucntions
source ${BIN_PATH:-./Infrastructure/bin}/utils.sh

echo "--- Setting up Parks Production Environment in project ${NAMESPACE_PROD}. ---"

# Code to # Set up the parks production project. It will need a StatefulSet MongoDB, and two applications each (Blue/Green) for NationalParks, MLBParks and Parksmap.
# The Green services/routes need to be active initially to guarantee a successful grading pipeline run.

# To be Implemented by Student
oc project ${NAMESPACE_PROD}

# Grant the correct permissions to the Jenkins service account
oc adm policy add-role-to-user edit system:serviceaccount:${NAMESPACE_JENKINS}:jenkins -n ${NAMESPACE_PROD}

# Grant the correct permissions to pull images from the development project
oc adm policy add-role-to-user system:image-puller system:serviceaccounts:${NAMESPACE_PROD} -n ${NAMESPACE_DEV}

# Grant the correct permissions for the ParksMap application to read back-end services (see the associated README file)
oc adm policy add-role-to-user view -z default -n ${NAMESPACE_PROD}

# Set up a replicated MongoDB database via StatefulSet with at least three replicas
MONGODB_TEMPLATE="${TEMPLATE_PATH:-./Infrastructure/templates/mongodb-petset-persistent.yml}"
DB_REPLICASET="rs0"
create_mongodb

# Set up blue and green instances for each of the three microservices
# For all the DeploymentConfig
APP_IMAGESTREAMTAG="1.0"
NAMESPACE="${GUID}-parks-prod"

# For MLBParks (Blue)
CONTEXT_DIR=MLBParks
_APP_NAME=$(echo ${CONTEXT_DIR} | tr '[:upper:]' '[:lower:]')
APP_NAME=$(echo ${_APP_NAME}-blue)
APP_DESCRIPTION="MLB Parks (Blue)"
deploy_application
oc delete route ${APP_NAME}

# For MLBParks (Green)
APP_NAME=$(echo ${_APP_NAME}-green)
APP_DESCRIPTION="MLB Parks (Green)"
deploy_application
oc delete route ${APP_NAME}
switch_green

# For Nationalparks (Blue)
CONTEXT_DIR=Nationalparks
_APP_NAME=$(echo ${CONTEXT_DIR} | tr '[:upper:]' '[:lower:]')
APP_NAME=$(echo ${_APP_NAME}-blue)
APP_DESCRIPTION="National Parks (Blue)"
deploy_application
oc delete route ${APP_NAME}

# For Nationalparks (Green)
APP_NAME=$(echo ${_APP_NAME}-green)
APP_DESCRIPTION="National Parks (Green)"
deploy_application
oc delete route ${APP_NAME}
switch_green

# For ParksMap (Blue)
CONTEXT_DIR=ParksMap
_APP_NAME=$(echo ${CONTEXT_DIR} | tr '[:upper:]' '[:lower:]')
APP_NAME=$(echo ${_APP_NAME}-blue)
APP_DESCRIPTION="ParksMap (Blue)"
BACKEND_SERVICE=""
deploy_application
oc set deployment-hook dc/${APP_NAME} --remove --post
oc delete route ${APP_NAME}

# For ParksMap (Green)
APP_NAME=$(echo ${_APP_NAME}-green)
APP_DESCRIPTION="ParksMap (Green)"
BACKEND_SERVICE=""
deploy_application
oc set deployment-hook dc/${APP_NAME} --remove --post
oc delete route ${APP_NAME}
switch_green
