#!/bin/bash
# Create all Homework Projects
if [ "$#" -ne 2 ]; then
  echo "Usage:"
  echo "  $0 GUID USER"
  exit 1
fi

GUID=${1:-}
USER=${2:-}

# Load variables and fucntions
source ${BIN_PATH:-./Infrastructure/bin}/utils.sh

if [ "$(oc whoami)" != "${USER}" ]; then
  echo "You need to switch to ${USER}"
  exit 1
fi

echo "Creating all Homework Projects for GUID=${GUID} and USER=${USER}"
oc new-project ${NAMESPACE_NEXUS} --display-name="${GUID} AdvDev Homework Nexus"
oc new-project ${NAMESPACE_SONAR} --display-name="${GUID} AdvDev Homework Sonarqube"
oc new-project ${NAMESPACE_JENKINS} --display-name="${GUID} AdvDev Homework Jenkins"
oc new-project ${NAMESPACE_DEV} --display-name="${GUID} AdvDev Homework Parks Development"
oc new-project ${NAMESPACE_PROD} --display-name="${GUID} AdvDev Homework Parks Production"
