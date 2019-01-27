#!/bin/bash
# Setup Development Project
if [ "$#" -ne 1 ]; then
    echo "Usage:"
    echo "  $0 GUID"
    exit 1
fi

GUID=${1:-}

# Load variables and fucntions
source ${BIN_PATH:-./Infrastructure/bin}/utils.sh

echo "--- Setting up Parks Development Environment in project ${NAMESPACE_DEV}. ---"
oc project ${NAMESPACE_DEV}

# Grant permissions to the Jenkins service account
oc adm policy add-role-to-user edit system:serviceaccount:${NAMESPACE_JENKINS}:jenkins -n ${NAMESPACE_DEV}

# Grant the correct permissions for the ParksMap application to read back-end services (see the associated README file)
oc adm policy add-role-to-user view -z default -n ${NAMESPACE_DEV}

# Create a MongoDB database
MONGODB_TEMPLATE="../templates/mongodb-persistent.yml"
create_mongodb

# application-template.yml requires NAMESPACE variable for execNewPod to load data.
NAMESPACE="${GUID}-parks-dev"
APP_IMAGESTREAMTAG="latest"

# For MLBParks
CONTEXT_DIR=MLBParks
APP_NAME=$(echo ${CONTEXT_DIR} | tr '[:upper:]' '[:lower:]')
APP_DESCRIPTION="MLB Parks (Dev)"
APP_IMAGE=jboss-eap70-openshift:1.7
remove_buildconfig_binary
create_buildconfig_binary
remove_application
deploy_application
start_pipeline

# For Nationalparks
CONTEXT_DIR=Nationalparks
APP_NAME=$(echo ${CONTEXT_DIR} | tr '[:upper:]' '[:lower:]')
APP_DESCRIPTION="National Parks (Dev)"
APP_IMAGE=redhat-openjdk18-openshift:1.2
remove_buildconfig_binary
create_buildconfig_binary
remove_application
deploy_application
start_pipeline

# For ParksMap
CONTEXT_DIR=ParksMap
APP_NAME=$(echo ${CONTEXT_DIR} | tr '[:upper:]' '[:lower:]')
APP_DESCRIPTION="ParksMap (Dev)"
APP_IMAGE=redhat-openjdk18-openshift:1.2
BACKEND_SERVICE=""
remove_buildconfig_binary
create_buildconfig_binary
remove_application
deploy_application
oc set deployment-hook dc/${APP_NAME} --remove --post
start_pipeline
