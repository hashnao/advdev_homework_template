#!/bin/bash
# Create all Homework Projects
if [ "$#" -ne 2 ]; then
  echo "Usage:"
  echo "  $0 GUID USER"
  exit 1
fi

GUID=$1
USER=$2

if [ "$(oc whoami)" != "${USER}" ]; then
  echo "You need to switch to ${USER}"
  exit 1
fi

echo "Creating all Homework Projects for GUID=${GUID} and USER=${USER}"
oc new-project ${GUID}-nexus      --display-name="${GUID} AdvDev Homework Nexus"
oc new-project ${GUID}-sonarqube  --display-name="${GUID} AdvDev Homework Sonarqube"
oc new-project ${GUID}-jenkins    --display-name="${GUID} AdvDev Homework Jenkins"
oc new-project ${GUID}-parks-dev  --display-name="${GUID} AdvDev Homework Parks Development"
oc new-project ${GUID}-parks-prod --display-name="${GUID} AdvDev Homework Parks Production"

cat >> EOF
If "redhat/openshift-ovs-multitenant" plugin is used and multi tenant is enabled, you need to allow the projects join the existing project network.
Otherwise it fails to push/pull libraries or images from the nexus repositories or connecting to the sonarqubej
Run the following command.
oc login -u system:admin
oc adm pod-network join-projects --to=${GUID}-jenkins ${GUID}-nexus ${GUID}-sonarqube ${GUID}-parks-dev ${GUID}-parks-prod
EOF
