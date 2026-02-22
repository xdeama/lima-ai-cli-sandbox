#!/bin/bash

if [ -z "$1" ]; then
    echo "Usage: ./delete.sh <vm_name>"
    exit 1
fi

VM_NAME=$1

if [ -f .env ]; then
    set -a
    source .env
    set +a
fi

echo "Stopping $VM_NAME."
limactl stop "$VM_NAME" 

echo "Deleting $VM_NAME."
limactl delete "$VM_NAME"

echo "Deleting [localhost]:${VM_SSH_PORT} from trusted ssh servers."
ssh-keygen -R "[localhost]:${VM_SSH_PORT}"

echo "Fully removed $VM_NAME."