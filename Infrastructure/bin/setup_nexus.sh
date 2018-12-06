#!/bin/bash
# Setup Nexus Project
if [ "$#" -ne 1 ]; then
    echo "Usage:"
    echo "  $0 GUID"
    exit 1
fi

GUID=$1
echo "Setting up Nexus in project $GUID-nexus"

# Set up nexus
oc project ${GUID}-nexus
oc new-app -f ../templates/nexus3-persistent.yml
oc rollout status dc nexus

cat >> EOF
You need to enable a docker registry through the nexus console because a registry is not created by default.
Check the URL with "oc get route nexus", then log in to the console to create a docker registry.
EOF
