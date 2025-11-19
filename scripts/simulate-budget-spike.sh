#!/usr/bin/env bash
set -euo pipefail
# Quick way to test budget alerts: create a one-off budget with a tiny amount.
SUBSCRIPTION_ID="${SUBSCRIPTION_ID:-$(az account show --query id -o tsv)}"
UPN="${1:-you@contoso.com}"
AMOUNT="${2:-5}"
NAME="test-${UPN//[@.]/-}"

AG_ID="${AG_ID:-$(az monitor action-group list --query "[0].id" -o tsv)}"
if [[ -z "$AG_ID" ]]; then
  echo "No Action Group found in this subscription. Provide AG_ID=... env var."
  exit 1
fi

az consumption budget create \
  --subscription $SUBSCRIPTION_ID \
  --amount $AMOUNT \
  --time-grain Monthly \
  --name "$NAME" \
  --start-date "$(date +%Y-%m-01)" \
  --end-date "2030-01-01" \
  --category Cost \
  --resource-group-filter "" \
  --tag-filter "ade:userUpn=$UPN" \
  --notifications '{
    "80": {"operator":"EqualTo","threshold":80,"contactGroups":["'"$AG_ID"'"],"enabled": true},
    "90": {"operator":"EqualTo","threshold":90,"contactGroups":["'"$AG_ID"'"],"enabled": true},
    "95": {"operator":"EqualTo","threshold":95,"contactGroups":["'"$AG_ID"'"],"enabled": true},
    "100":{"operator":"EqualTo","threshold":100,"contactGroups":["'"$AG_ID"'"],"enabled": true}
  }' -o table

echo "Created tiny budget $NAME for $UPN — spend a little to trigger alerts."
