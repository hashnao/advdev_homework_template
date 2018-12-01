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
