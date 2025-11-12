# Azure Functions Deployment Checklist

## ✅ Fixed Issues:

1. **Removed invalid `use_monitor=False` parameter** from timer trigger decorator
   - Azure Functions Python v2 doesn't support this parameter
   - This was causing "could not load functions" error

2. **Validated syntax** - function_app.py structure is correct:
   - ✅ app = func.FunctionApp() instance exists
   - ✅ @app.timer_trigger decorator is properly formatted
   - ✅ Function signature is correct

## 🚀 Deploy Now:

From the `expirationRunNow` directory, run:

```bash
# Create clean deployment package
zip -r function.zip . -x "*.git*" -x "*__pycache__*" -x "*.pyc" -x ".env*" -x "venv/*" -x "demo_*" -x "test_*" -x "*.DS_Store" -x "validate_*"

# Deploy
az functionapp deployment source config-zip \
  --resource-group <YOUR_RG> \
  --name <YOUR_FUNCTION_APP> \
  --src function.zip \
  --timeout 300
```

## 📋 Post-Deployment:

1. **Set Environment Variables** in Azure Portal → Configuration:
   - `ADE_SUBSCRIPTION_ID` = your subscription ID
   - `SLACK_WEBHOOK_URL` = your Slack webhook URL

2. **Grant Permissions** (if not already done):
   ```bash
   az role assignment create \
     --assignee <function-app-managed-identity-id> \
     --role "Reader" \
     --scope "/subscriptions/<subscription-id>"
   ```

3. **Verify in Portal**:
   - Go to Function App → Functions
   - You should see "expirationDateNotice" listed
   - Check "Monitor" tab for execution logs

## 🐛 If Still Getting Errors:

1. Check Application Insights logs
2. Verify Python runtime version matches (3.9, 3.10, or 3.11)
3. Ensure no other functions exist in the deployment
