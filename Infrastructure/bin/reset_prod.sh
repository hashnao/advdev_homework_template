#!/bin/bash
# Reset Production Project (initial active services: Blue)
# This sets all services to the Blue service so that any pipeline run will deploy Green
if [ "$#" -ne 1 ]; then
    echo "Usage:"
    echo "  $0 GUID"
    exit 1
fi

GUID=$1

# Load variables and fucntions
source ${BIN_PATH:-./Infrastructure/bin}/utils.sh

echo "--- Resetting Parks Production Environment in project ${NAMESPACE_PROD} to Green Services. ---"

oc project ${NAMESPACE_PROD}
echo "--- Setting pod replica for green application with 0 and blue with 1."
ALL_APPLICATIONS="mlbparks nationalparks parksmap"
for i in ${ALL_APPLICATIONS} ; do
  oc scale dc ${i}-blue --replicas=0
  oc scale dc ${i}-green --replicas=1
  oc rollout status dc ${i}-green -w
done
# For backend services
BACKEND_APPLICATIONS="mlbparks nationalparks"
for i in ${BACKEND_APPLICATIONS} ; do
  oc label service ${i}-blue type-
  oc label service ${i}-green type=${BACKEND_SERVICE} --overwrite
done

# For route
_APP_NAME=parksmap
oc set route-backends ${_APP_NAME} ${_APP_NAME}-blue=0 ${_APP_NAME}-green=100
