#!/bin/bash
# Setup Jenkins Project
if [ "$#" -ne 3 ]; then
    echo "Usage:"
    echo "  $0 GUID REPO CLUSTER"
    echo "  Example: $0 wkha https://github.com/wkulhanek/ParksMap na39.openshift.opentlc.com"
    exit 1
fi

GUID=$1
REPO=$2
CLUSTER=$3
echo "Setting up Jenkins in project ${GUID}-jenkins from Git Repo ${REPO} for Cluster ${CLUSTER}"
MAVEN_SLAVE_IMAGE=jenkins-slave-appdev

# Create custom agent container image with skopeo
oc project ${GUID}-jenkins
cat ../dockerfiles/Dockerfile | oc new-build --dockerfile=- --to=${MAVEN_SLAVE_IMAGE}
oc label is ${MAVEN_SLAVE_IMAGE} role=jenkins-slave

# Set up Jenkins with sufficient resources
oc rollout status dc jenkins
if [ "$?" -ne 0 ]; then
  oc new-app -f ../templates/jenkins-persistent.yml
fi
oc rollout status dc jenkins

# Build artifact and image
CONTEXT_DIR=MLBParks
APP_NAME=$(echo ${CONTEXT_DIR} | tr '[:upper:]' '[:lower:]')
APP_IMAGE=jboss-eap70-openshift:1.7
oc new-build ${REPO} --strategy=pipeline --context-dir=${CONTEXT_DIR} \
-e MAVEN_SLAVE_IMAGE=${MAVEN_SLAVE_IMAGE} -e CONTEXT_DIR=${CONTEXT_DIR} \
-e GUID=${GUID} -e GIT_SOURCE_URL=${REPO} -e APP_IMAGE=${APP_IMAGE} \
--name=${APP_NAME}

CONTEXT_DIR=Nationalparks
APP_NAME=$(echo ${CONTEXT_DIR} | tr '[:upper:]' '[:lower:]')
APP_IMAGE=redhat-openjdk18-openshift:1.2
oc new-build ${REPO} --strategy=pipeline --context-dir=${CONTEXT_DIR} \
-e MAVEN_SLAVE_IMAGE=${MAVEN_SLAVE_IMAGE} -e CONTEXT_DIR=${CONTEXT_DIR} \
-e GUID=${GUID} -e GIT_SOURCE_URL=${REPO} -e APP_IMAGE=${APP_IMAGE} \
--name=${APP_NAME}

CONTEXT_DIR=ParksMap
APP_NAME=$(echo ${CONTEXT_DIR} | tr '[:upper:]' '[:lower:]')
APP_IMAGE=redhat-openjdk18-openshift:1.2
oc new-build ${REPO} --strategy=pipeline --context-dir=${CONTEXT_DIR} \
-e MAVEN_SLAVE_IMAGE=${MAVEN_SLAVE_IMAGE} -e CONTEXT_DIR=${CONTEXT_DIR} \
-e GUID=${GUID} -e GIT_SOURCE_URL=${REPO} -e APP_IMAGE=${APP_IMAGE} \
--name=${APP_NAME}
