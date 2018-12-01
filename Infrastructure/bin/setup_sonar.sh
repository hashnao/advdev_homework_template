#!/bin/bash
# Setup Sonarqube Project
if [ "$#" -ne 1 ]; then
    echo "Usage:"
    echo "  $0 GUID"
    exit 1
fi

GUID=$1
echo "Setting up Sonarqube in project $GUID-sonarqube"

# Set up SonarQube
oc project ${GUID}-sonarqube
POSTGRESQL_USER=sonar
POSTGRESQL_PASSWORD=sonar
POSTGRESQL_DATABASE=sonar

oc new-app --template=postgresql-persistent \
-p POSTGRESQL_USER=${POSTGRESQL_USER} \
-p POSTGRESQL_PASSWORD=${POSTGRESQL_PASSWORD} \
-p POSTGRESQL_DATABASE=${POSTGRESQL_DATABASE}
oc rollout status dc postgresql

oc new-app -f ../templates/sonarqube-persistent.yml \
-p POSTGRESQL_USER=${POSTGRESQL_USER} \
-p POSTGRESQL_PASSWORD=${POSTGRESQL_PASSWORD} \
-p POSTGRESQL_DATABASE=${POSTGRESQL_DATABASE}
oc rollout status dc sonarqube
