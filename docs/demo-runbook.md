# ADE Plug & Play Demo

1. **Configure repo** (secrets + vars), push branch `feat/functions-notifications-and-expiration`.
2. **Run GitHub Action** `Deploy Infra`.
3. **Set Slack secret**: `./scripts/set-kv-secrets.sh <kv-name> SLACK-WEBHOOK-URL https://hooks.slack.com/...`
4. **Seed sample env**: `./scripts/seed-ade-templates.sh` (creates RG + tags).
5. **Test Slack**: `./scripts/send-test-slack.sh https://hooks.slack.com/... "ADE pipeline wired!"`
6. **Simulate budget**: `AG_ID=<actionGroupId> ./scripts/simulate-budget-spike.sh you@contoso.com 5`
7. **Expiration**: set `EXPIRES_ON=$(date -u -d '+1 day' +%F)` in seed script to see 1-day warning, or backdate to trigger delete.
