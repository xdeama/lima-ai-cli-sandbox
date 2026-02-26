#!/bin/bash

if [ -f .env ]; then
    set -a
    source .env
    set +a
fi

VM_NAME=${1:-$VM_NAME}

if [ -z "$VM_NAME" ]; then
    echo "Error: No VM name provided. Pass as argument or set VM_NAME in .env"
    exit 1
fi

echo "Stopping $VM_NAME."
limactl stop "$VM_NAME"

echo "Deleting $VM_NAME."
limactl delete "$VM_NAME"

echo "Deleting [localhost]:${VM_SSH_PORT} from trusted ssh servers."
ssh-keygen -R "[localhost]:${VM_SSH_PORT}"

echo "Fully removed $VM_NAME."
