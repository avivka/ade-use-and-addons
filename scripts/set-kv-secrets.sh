#!/usr/bin/env bash
set -euo pipefail
# Usage: ./set-kv-secrets.sh <kv-name> <secret-name> <secret-value>
KV_NAME="${1:?keyvault name}"
SEC_NAME="${2:?secret name}"
SEC_VAL="${3:?secret value}"

az keyvault secret set --vault-name "$KV_NAME" --name "$SEC_NAME" --value "$SEC_VAL" -o table
echo "Set secret $SEC_NAME in $KV_NAME"
