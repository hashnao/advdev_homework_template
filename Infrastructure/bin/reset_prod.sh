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

echo "--- Scaling down blue pod replica to 0 and out green pod to 1. ---"
ALL_APPLICATIONS="mlbparks nationalparks parksmap"
for i in ${ALL_APPLICATIONS} ; do
  oc scale dc ${i}-blue --replicas=0
  oc scale dc ${i}-green --replicas=1
  oc rollout status dc ${i}-green -w
done

echo "--- Setting the backend service label on only the green service. ---"
BACKEND_APPLICATIONS="mlbparks nationalparks"
for i in ${BACKEND_APPLICATIONS} ; do
  oc label service ${i}-blue type="" --overwrite
  oc label service ${i}-green type=${BACKEND_SERVICE} --overwrite
done

echo "--- Setting weight of green service for route. ---"
for i in ${ALL_APPLICATIONS} ; do
  oc set route-backends ${i} ${i}-blue=0 ${i}-green=100
done
