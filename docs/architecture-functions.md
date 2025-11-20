# ADE Notifications via Azure Functions

- **budgetAlertHandler (HTTP)**: target of Azure Monitor Action Group for Budget thresholds (80/90/95/100%).
- **expirationSweep (Timer)**: scans RGs tagged with `ade:expiresOn`, warns at 7d/1d, deletes past-due, posts Slack.

Infra:
- Function App (Python, Consumption), Managed Identity
- Key Vault with `SLACK-WEBHOOK-URL` secret; Function uses KV reference
- Policy enforces `ade:expiresOn`
- Budgets filtered by `ade:userUpn` tag per-user
