#!/bin/bash
# Setup Jenkins Project
if [ "$#" -ne 3 ]; then
    echo "Usage:"
    echo "  $0 GUID REPO CLUSTER"
    echo "  Example: $0 wkha https://github.com/wkulhanek/ParksMap na39.openshift.opentlc.com"
    exit 1
fi

# Variable arguments
GUID=${1:-}
REPO=${2:-https://github.com/hashnao/advdev_homework_template}
CLUSTER=${3:-na39.openshift.opentlc.com}

# Default variables
MAVEN_SLAVE_IMAGE=jenkins-slave-appdev
MAVEN_PATH=/opt/rh/rh-maven35/root/usr/bin
JENKINS_SLAVE_CPU_REQUEST=500m
JENKINS_SLAVE_CPU_LIMIT=2
JENKINS_SLAVE_MEMORY_REQUEST=1Gi
JENKINS_SLAVE_MEMORY_LIMIT=2Gi
GIT_SOURCE_REF=master
NEXUS_URL="http://nexus.${GUID}-nexus.svc:8081"
NEXUS_URI_MAVEN="repository/maven-releases"
NEXUS_URI_PUBLIC="repository/maven-all-public"
NEXUS_REGISTRY_URL="docker://nexus-registry.${GUID}-nexus.svc:5000/repository/registry"
NEXUS_USER=admin
NEXUS_PASSWORD=admin123
SONAR_URL="http://sonarqube.${GUID}-sonarqube.svc:9000"
REGISTRY_URL="docker://docker-registry.default.svc:5000"

start_binary_build() {
  oc new-build ${REPO} --strategy=pipeline --context-dir=${CONTEXT_DIR} --name=${APP_NAME}-pipeline \
  -e APP_NAME=${APP_NAME} \
  -e APP_IMAGE=${APP_IMAGE} \
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
  -e NEXUS_USER=${NEXUS_USER} \
  -e NEXUS_PASSWORD=${NEXUS_PASSWORD} \
  -e SONAR_URL=${SONAR_URL} \
  -e REGISTRY_URL=${REGISTRY_URL}
}

echo "Setting up Jenkins in project ${GUID}-jenkins from Git Repo ${REPO} for Cluster ${CLUSTER}"

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
start_binary_build

CONTEXT_DIR=Nationalparks
APP_NAME=$(echo ${CONTEXT_DIR} | tr '[:upper:]' '[:lower:]')
APP_IMAGE=redhat-openjdk18-openshift:1.2
start_binary_build

CONTEXT_DIR=ParksMap
APP_NAME=$(echo ${CONTEXT_DIR} | tr '[:upper:]' '[:lower:]')
APP_IMAGE=redhat-openjdk18-openshift:1.2
start_binary_build
