#!/bin/bash
# Delete all Homework Projects
if [ "$#" -ne 1 ]; then
    echo "Usage:"
    echo "  $0 GUID"
    exit 1
fi

GUID=${1:-}

# Load variables and fucntions
source ./utils.sh

echo "Removing all Homework Projects for GUID=$GUID"
NAMESPACES="${NAMESPACE_JENKINS} ${NAMESPACE_NEXUS} ${NAMESPACE_SONAR} ${NAMESPACE_DEV} ${NAMESPACE_PROD}"
for NAMESPACE in ${NAMESPACES} ; do
  oc delete project ${NAMESPACE}
done
