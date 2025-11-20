#!/usr/bin/env bash
set -euo pipefail
WEBHOOK="${1:?slack webhook}"
MSG="${2:-Hello from ADE test}"
curl -X POST -H "Content-type: application/json" --data "{\"text\":\"$MSG\"}" "$WEBHOOK"
echo
