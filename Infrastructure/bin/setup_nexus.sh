#!/bin/bash
# Setup Nexus Project
if [ "$#" -ne 1 ]; then
    echo "Usage:"
    echo "  $0 GUID"
    exit 1
fi

GUID=${1:-}

# Load variables and fucntions
source ./utils.sh

echo "--- Setting up Nexus in project ${NAMESPACE_NEXUS}. ---"

# Set up nexus
oc project ${NAMESPACE_NEXUS}
oc new-app -f ../templates/nexus3-persistent.yml
oc expose service nexus-registry
oc rollout status dc nexus

cat << EOF
Log in to the nexus admin console and create a container image registry.
The console URL is as follows.
http://nexus-${NAMESPACE_NEXUS}.${CLUSTER}/#admin/repository/repositories
EOF
