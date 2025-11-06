#!/usr/bin/env bash
set -euo pipefail

# ─────────────────────────────────────────────────────────────
# Config
export SLACK_MOCK=1                 # route Slack to console
export DRY_DELETE=1                 # do not actually delete RGs
export ADE_SUBSCRIPTION_ID="${ADE_SUBSCRIPTION_ID:-$(az account show --query id -o tsv)}"
DEMO_DIR="$(cd "$(dirname "$0")/.." && pwd)"
PFX="${PFX:-ade-demo}"
TODAY="$(date -u +%F)"

echo "== ADE E2E MOCK DEMO (date: $TODAY) =="

# ─────────────────────────────────────────────────────────────
# 1) Start Functions locally (in background)
echo ">> Starting local Azure Functions host..."
pushd "$DEMO_DIR/src/functions" >/dev/null
# ensure deps (local venv optional)
python3 -m pip install -q -r requirements.txt -t ./
func start &            # requires Azure Functions Core Tools
FUNC_PID=$!
popd >/dev/null
sleep 5

# ─────────────────────────────────────────────────────────────
# 2) Create mock ADE envs (RGs with tags)
echo ">> Creating mock ADE envs..."
"$DEMO_DIR/scripts/fixtures-create-envs.sh"

# ─────────────────────────────────────────────────────────────
# 3) Trigger a 90% budget alert (sample payload)
echo ">> Sending sample Budget Alert (90%) to budgetAlertHandler..."
curl -sS -X POST "http://localhost:7071/api/budgetAlert" \
  -H "Content-Type: application/json" \
  --data @"$DEMO_DIR/samples/budget-alert-common-schema.json" | sed -e 's/^/   /'
echo

# ─────────────────────────────────────────────────────────────
# 4) Run expiration sweep (manual HTTP)
echo ">> Running expiration sweep (HTTP runNow)..."
curl -sS "http://localhost:7071/api/expiration/runNow" | sed -e 's/^/   /'
echo

# ─────────────────────────────────────────────────────────────
# 5) Show captured mock Slack lines
echo ">> MOCK Slack outputs (tail of function host log):"
# We can’t read host logs portably; instead, re-run sweep once more to emit lines deterministically.
curl -sS "http://localhost:7071/api/expiration/runNow" >/dev/null || true
echo "   (see above [MOCK-SLACK ...] lines for budget + expiration + delete notices)"

# ─────────────────────────────────────────────────────────────
# 6) Cleanup (stop host)
echo ">> Stopping Functions host..."
kill $FUNC_PID || true
wait $FUNC_PID 2>/dev/null || true

echo "== DEMO COMPLETE =="
