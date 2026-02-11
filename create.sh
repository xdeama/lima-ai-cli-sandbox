#!/bin/bash

# Usage: ./start.sh <template.yaml> [optional_vm_name]

# 1. Validate YAML input
if [ -z "$1" ]; then
    echo "Usage: ./start.sh <config.yaml> [vm_name]"
    exit 1
fi

YAML_TEMPLATE=$1

# 2. Load variables from .env
if [ -f .env ]; then
    set -a
    source .env
    set +a
else
    echo "Error: .env file not found."
    exit 1
fi

# 3. Determine VM Name (Argument 2 OR .env OR filename)
# This uses the 2nd argument if provided, otherwise the .env variable
TARGET_NAME=${2:-$VM_NAME}

if [ -z "$TARGET_NAME" ]; then
    echo "Error: No VM name provided as argument or found in .env"
    exit 1
fi

# 4. Start/Create the VM
# We use <() process substitution to pass the 'baked' YAML as a file
if limactl list | grep -q "^${TARGET_NAME} "; then
    echo "Instance '${TARGET_NAME}' exists. Starting..."
    limactl start "${TARGET_NAME}"
else
    echo "Creating instance '${TARGET_NAME}' from ${YAML_TEMPLATE}..."
    limactl start --name="${TARGET_NAME}" <(envsubst < "$YAML_TEMPLATE")
fi