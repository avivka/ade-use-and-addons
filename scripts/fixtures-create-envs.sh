#!/usr/bin/env bash
set -euo pipefail
# Creates two RGs: one expiring in 7 days, one already expired yesterday.
# Requires: az login

LOCATION="${LOCATION:-centralcanada}"
OWNER1="${OWNER1:-avivkabesa@microsoft.com}"
OWNER2="${OWNER2:-yanivnorman@microsoft.com}"

RG1="ade-alice-demo-rg"
RG2="ade-bob-expired-rg"
EXP1="$(date -u -d '+7 days' +%F)"
EXP2="$(date -u -d '-1 day' +%F)"

az group create -n "$RG1" -l "$LOCATION" -o none
az group create -n "$RG2" -l "$LOCATION" -o none

az group update -n "$RG1" --set tags."ade:expiresOn"="$EXP1" tags."ade:userUpn"="$OWNER1" -o none
az group update -n "$RG2" --set tags."ade:expiresOn"="$EXP2" tags."ade:userUpn"="$OWNER2" -o none

echo "Created RGs:"
echo "  $RG1  expiresOn=$EXP1  owner=$OWNER1"
echo "  $RG2  expiresOn=$EXP2  owner=$OWNER2  (expired)"
