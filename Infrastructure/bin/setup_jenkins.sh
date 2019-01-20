#!/bin/bash
# Setup Jenkins Project
if [ "$#" -ne 3 ]; then
    echo "Usage:"
    echo "  $0 GUID REPO CLUSTER"
    echo "  Example: $0 wkha https://github.com/wkulhanek/ParksMap na39.openshift.opentlc.com"
    exit 1
fi

# Load variables and fucntions
source ./utils.sh

# Variable arguments
GUID=${1:-}
REPO=${2:-https://github.com/hashnao/advdev_homework_template}
CLUSTER=${3:-apps.na311.openshift.opentlc.com}

# Default variables
MAVEN_SLAVE_IMAGE=jenkins-slave-appdev
MAVEN_PATH=/opt/rh/rh-maven35/root/usr/bin
JENKINS_SLAVE_CPU_REQUEST=500m
JENKINS_SLAVE_CPU_LIMIT=2
JENKINS_SLAVE_MEMORY_REQUEST=1Gi
JENKINS_SLAVE_MEMORY_LIMIT=2Gi
GIT_SOURCE_REF=master
NEXUS_URL="http://nexus.${NAMESPACE_NEXUS}.svc:8081"
NEXUS_URI_MAVEN="repository/maven-releases"
NEXUS_URI_PUBLIC="repository/maven-all-public"
NEXUS_REGISTRY_URL="docker://nexus-registry.${NAMESPACE_NEXUS}.svc:5000/repository/registry"
NEXUS_CREDENTIALS_ID="nexus"
NEXUS_USER="admin"
NEXUS_PASSWORD="admin123"
SONAR_URL="http://sonarqube.${NAMESPACE_SONAR}.svc:9000"
REGISTRY_URL="docker://docker-registry.default.svc:5000"

# Functions
create_jenkins_slave_image() {
  cat ../dockerfiles/Dockerfile | oc new-build --dockerfile=- --to=${MAVEN_SLAVE_IMAGE}
  oc label is ${MAVEN_SLAVE_IMAGE} role=jenkins-slave
}

deploy_jenkins() {
  oc rollout status dc jenkins
  if [ "$?" -ne 0 ]; then
    oc new-app -f ${TEMPLATE}
  fi
  oc rollout status dc jenkins
}

create_jenkins_credentials() {
  curl -X POST -k -H "${HEADER}" "${URL}" --data-urlencode "json={
    '': '0',
    'credentials': {
      'scope': 'GLOBAL',
      'id': '${NEXUS_CREDENTIALS_ID}',
      'username': '${NEXUS_USER}',
      'password': '${NEXUS_PASSWORD}',
      'description': 'Nexus Administrator',
      'stapler-class': 'com.cloudbees.plugins.credentials.impl.UsernamePasswordCredentialsImpl'
    }
  }"
}

create_buildconfig_pipeline() {
  oc new-build ${REPO} --strategy=pipeline --context-dir=${CONTEXT_DIR} --name=${APP_NAME}-pipeline
  oc set env bc/${APP_NAME}-pipeline \
  -e APP_NAME=${APP_NAME} \
  -e APP_IMAGE=${APP_IMAGE} \
  -e BACKEND_SERVICE=${BACKEND_SERVICE} \
  -e CLUSTER=${CLUSTER} \
  -e MAVEN_SLAVE_IMAGE=${MAVEN_SLAVE_IMAGE} \
  -e CONTEXT_DIR=${CONTEXT_DIR} \
  -e GUID=${GUID} \
  -e GIT_SOURCE_URL=${REPO} \
  -e GIT_SOURCE_REF=${GIT_SOURCE_REF} \
  -e MAVEN_PATH=${MAVEN_PATH} \
  -e JENKINS_SLAVE_CPU_REQUEST=${JENKINS_SLAVE_CPU_REQUEST} \
  -e JENKINS_SLAVE_CPU_LIMIT=${JENKINS_SLAVE_CPU_LIMIT} \
  -e JENKINS_SLAVE_MEMORY_REQUEST=${JENKINS_SLAVE_MEMORY_REQUEST} \
  -e JENKINS_SLAVE_MEMORY_LIMIT=${JENKINS_SLAVE_MEMORY_LIMIT} \
  -e NEXUS_URL=${NEXUS_URL} \
  -e NEXUS_URI_MAVEN=${NEXUS_URI_MAVEN} \
  -e NEXUS_URI_PUBLIC=${NEXUS_URI_PUBLIC} \
  -e NEXUS_REGISTRY_URL=${NEXUS_REGISTRY_URL} \
  -e SONAR_URL=${SONAR_URL} \
  -e REGISTRY_URL=${REGISTRY_URL} \
  -e NAMESPACE_JENKINS=${NAMESPACE_JENKINS} \
  -e NAMESPACE_DEV=${NAMESPACE_DEV} \
  -e NAMESPACE_PROD=${NAMESPACE_PROD}
}

delete_buildconfig_pipeline() {
  oc get bc/${APP_NAME}-pipeline >/dev/null 2>&1
  if [ "$?" -eq 0 ]; then
    oc delete all -l build=${APP_NAME}-pipeline
  fi
}

echo "--- Setting up Jenkins in project ${NAMESPACE_JENKINS} from Git Repo ${REPO} for Cluster ${CLUSTER} ---"

# Create custom agent container image with skopeo
oc project ${NAMESPACE_JENKINS}
create_jenkins_slave_image

# Set up Jenkins with sufficient resources
TEMPLATE="../templates/jenkins-persistent.yml"
deploy_jenkins

# Create Jenkins credentials for Nexus via the REST API
TOKEN=$(oc whoami -t)
URL="https://$(oc get route jenkins --template='{{ .spec.host }}')/credentials/store/system/domain/_/createCredentials"
HEADER="Authorization: Bearer ${TOKEN}"
# Wait for Jenkins container running.
sleep 30
create_jenkins_credentials

# Build artifact and image
CONTEXT_DIR=MLBParks
APP_NAME=$(echo ${CONTEXT_DIR} | tr '[:upper:]' '[:lower:]')
delete_buildconfig_pipeline
create_buildconfig_pipeline

CONTEXT_DIR=Nationalparks
APP_NAME=$(echo ${CONTEXT_DIR} | tr '[:upper:]' '[:lower:]')
delete_buildconfig_pipeline
create_buildconfig_pipeline

CONTEXT_DIR=ParksMap
APP_NAME=$(echo ${CONTEXT_DIR} | tr '[:upper:]' '[:lower:]')
delete_buildconfig_pipeline
create_buildconfig_pipeline
