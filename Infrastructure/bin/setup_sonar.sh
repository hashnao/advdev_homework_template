#!/bin/bash
# Setup Sonarqube Project
if [ "$#" -ne 1 ]; then
    echo "Usage:"
    echo "  $0 GUID"
    exit 1
fi

GUID=${1:-}

# Load variables and fucntions
source ${BIN_PATH:-./Infrastructure/bin}/utils.sh

echo "--- Setting up Sonarqube in project ${NAMESPACE_SONAR}. ---"

# Set up SonarQube
oc project ${NAMESPACE_SONAR}
POSTGRESQL_USER=sonar
POSTGRESQL_PASSWORD=sonar
POSTGRESQL_DATABASE=sonar

oc new-app --template=postgresql-persistent \
-p POSTGRESQL_USER=${POSTGRESQL_USER} \
-p POSTGRESQL_PASSWORD=${POSTGRESQL_PASSWORD} \
-p POSTGRESQL_DATABASE=${POSTGRESQL_DATABASE}
oc rollout status dc postgresql

oc new-app -f ${TEMPLATE_PATH:-./Infrastructure/templates/sonarqube-persistent.yml} \
-p POSTGRESQL_USER=${POSTGRESQL_USER} \
-p POSTGRESQL_PASSWORD=${POSTGRESQL_PASSWORD} \
-p POSTGRESQL_DATABASE=${POSTGRESQL_DATABASE}
oc rollout status dc sonarqube
