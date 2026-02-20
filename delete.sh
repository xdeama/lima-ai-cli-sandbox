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

limactl stop "$VM_NAME" && limactl delete "$VM_NAME" && ssh-keygen -R "[localhost]:${VM_SSH_PORT}"
