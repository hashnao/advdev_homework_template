#!/bin/#!/usr/bin/env bash

# Variables
TEMPLATE="../templates/application-template.yml"
NAMESPACE_NEXUS="${GUID}-nexus"
NAMESPACE_SONAR="${GUID}-sonar"
NAMESPACE_JENKINS="${GUID}-jenkins"
NAMESPACE_DEV="${GUID}-parks-dev"
NAMESPACE_PROD="${GUID}-parks-prod"
MONGODB_SERVICE_NAME="mongodb"
MONGODB_DATABASE="parks"
MONGODB_CONFIGMAP="mongodb"
MONGODB_USER="mongodb"
MONGODB_PASSWORD="mongodb"
MONGODB_ADMIN_PASSWORD="mongodbadmin"
MONGODB_HOST="mongodb"
MONGODB_PORT="27017"
BACKEND_SERVICE="parksmap-backend"

# Functions
remove_buildconfig_binary() {
  oc get bc/${APP_NAME} >/dev/null 2>&1
  if [ "$?" -eq 0 ]; then
    oc delete all -l build=${APP_NAME}
  fi
}

create_buildconfig_binary() {
  oc new-build --name=${APP_NAME} ${APP_IMAGE} \
  --to=${APP_NAME}:latest \
  --allow-missing-imagestream-tags=true \
  --allow-missing-images=true \
  --binary=true
}

start_pipeline() {
  oc start-build ${APP_NAME}-pipeline -n ${NAMESPACE_JENKINS}
}

create_mongodb () {
  oc new-app -f ${MONGODB_TEMPLATE} \
  --name=${MONGODB_SERVICE_NAME} \
  -p MONGODB_USER=${MONGODB_USER} \
  -p MONGODB_PASSWORD=${MONGODB_PASSWORD} \
  -p MONGODB_DATABASE=${MONGODB_DATABASE} \
  -p MONGODB_ADMIN_PASSWORD=${MONGODB_ADMIN_PASSWORD}

  oc create cm ${MONGODB_CONFIGMAP} \
  --from-literal=DB_HOST=${MONGODB_HOST} \
  --from-literal=DB_PORT=${MONGODB_PORT} \
  --from-literal=DB_USERNAME=${MONGODB_USER} \
  --from-literal=DB_PASSWORD=${MONGODB_PASSWORD} \
  --from-literal=DB_NAME=${MONGODB_DATABASE} \
  --from-literal=DB_DATABASE=${MONGODB_DATABASE}
}

remove_application() {
  oc get dc/${APP_NAME} >/dev/null 2>&1
  if [ "$?" -eq 0 ]; then
    oc delete all -l app=${APP_NAME}
  fi
}

deploy_application() {
  oc new-app -f ${TEMPLATE} \
  --allow-missing-imagestream-tags=true \
  --allow-missing-images=true \
  -p NAMESPACE=${NAMESPACE} \
  -p APP_NAME=${APP_NAME} \
  -p APP_IMAGESTREAMTAG=${APP_IMAGESTREAMTAG} \
  -p APP_DESCRIPTION="${APP_DESCRIPTION}" \
  -p BACKEND_SERVICE="${BACKEND_SERVICE}"
  oc set env dc/${APP_NAME} --from=configmap/${MONGODB_CONFIGMAP}
}

# Guarantee blue is used by removing the type lable
remove_backend_service_label() {
  oc label service ${APP_NAME} type-
}

switch_green() {
  oc delete route ${APP_NAME}
  oc expose service --name=${_APP_NAME} ${_APP_NAME}-green
  oc set route-backends ${_APP_NAME} ${_APP_NAME}-blue=0 ${_APP_NAME}-green=100
}
