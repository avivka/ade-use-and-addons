#!/usr/bin/env bash
set -euo pipefail
# This creates a sample RG and tags mimicking an ADE env definition outcome.
# In real ADE catalogs, ensure templates stamp ade:expiresOn and ade:userUpn.

SUBSCRIPTION_ID="${SUBSCRIPTION_ID:-$(az account show --query id -o tsv)}"
LOCATION="${LOCATION:-westeurope}"
OWNER_UPN="${OWNER_UPN:-you@contoso.com}"
EXPIRES_ON="${EXPIRES_ON:-$(date -u -d '+8 days' +%F)}"
NAME="${NAME:-ade-sample-env}"

az group create -n "${NAME}-rg" -l "$LOCATION" -o table
az group update -n "${NAME}-rg" --set tags."ade:expiresOn"="$EXPIRES_ON" tags."ade:userUpn"="$OWNER_UPN" -o table

echo "Seeded ${NAME}-rg with ade:expiresOn=$EXPIRES_ON and ade:userUpn=$OWNER_UPN"
