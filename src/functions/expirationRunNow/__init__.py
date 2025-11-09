import azure.functions as func
import logging
import os
import json
from datetime import datetime, timedelta, timezone
from typing import List, Dict, Optional
import requests
from azure.identity import DefaultAzureCredential

logger = logging.getLogger(__name__)


def get_azure_token(resource: str = "https://management.azure.com/") -> str:
    """Get Azure access token using managed identity or default credentials."""
    credential = DefaultAzureCredential()
    token = credential.get_token(resource + ".default")
    return token.token


def get_devcenter_token() -> str:
    """Get access token for Azure DevCenter API."""
    return get_azure_token("https://devcenter.azure.com/")


def fetch_all_environments() -> List[Dict]:
    """
    Fetch all Azure Deployment Environments using the DevCenter API.
    
    API Reference:
    https://learn.microsoft.com/en-us/rest/api/devcenter/developer/environments/list-environments-by-user
    """
    subscription_id = os.environ.get("ADE_SUBSCRIPTION_ID")
    dev_center = os.environ.get("ADE_DEV_CENTER")
    project_name = os.environ.get("ADE_PROJECT_NAME")
    
    if not all([subscription_id, dev_center, project_name]):
        raise ValueError("Missing required environment variables: ADE_SUBSCRIPTION_ID, ADE_DEV_CENTER, ADE_PROJECT_NAME")
    
    # Get token for DevCenter API
    token = get_devcenter_token()
    
    # Construct API endpoint
    # Using the user-specific API endpoint
    api_version = "2024-02-01"
    base_url = f"https://{dev_center}.devcenter.azure.com"
    endpoint = f"{base_url}/projects/{project_name}/users/me/environments?api-version={api_version}"
    
    headers = {
        "Authorization": f"Bearer {token}",
        "Content-Type": "application/json"
    }
    
    environments = []
    
    try:
        logger.info(f"Fetching environments from: {endpoint}")
        response = requests.get(endpoint, headers=headers, timeout=30)
        response.raise_for_status()
        
        data = response.json()
        
        # Handle paginated response
        if "value" in data:
            environments.extend(data["value"])
            
            # Check for next page
            while "nextLink" in data:
                logger.info(f"Fetching next page: {data['nextLink']}")
                response = requests.get(data["nextLink"], headers=headers, timeout=30)
                response.raise_for_status()
                data = response.json()
                if "value" in data:
                    environments.extend(data["value"])
        
        logger.info(f"Successfully fetched {len(environments)} environments")
        return environments
        
    except requests.exceptions.RequestException as e:
        logger.error(f"Failed to fetch environments: {str(e)}")
        if hasattr(e, 'response') and e.response is not None:
            logger.error(f"Response status: {e.response.status_code}")
            logger.error(f"Response body: {e.response.text}")
        raise


def parse_expiration_date(expiration_str: Optional[str]) -> Optional[datetime]:
    """Parse expiration date from ISO format string."""
    if not expiration_str:
        return None
    
    try:
        # Handle both with and without timezone
        if expiration_str.endswith('Z'):
            return datetime.fromisoformat(expiration_str.replace('Z', '+00:00'))
        else:
            dt = datetime.fromisoformat(expiration_str)
            # If no timezone, assume UTC
            if dt.tzinfo is None:
                dt = dt.replace(tzinfo=timezone.utc)
            return dt
    except Exception as e:
        logger.warning(f"Failed to parse expiration date '{expiration_str}': {e}")
        return None


def check_expiring_environments(warn_days: int = 3) -> List[Dict]:
    """
    Check all environments and return those that are expiring soon or already expired.
    
    Args:
        warn_days: Number of days before expiration to start warning (default: 3)
    
    Returns:
        List of dictionaries with environment details and expiration info
    """
    environments = fetch_all_environments()
    now = datetime.now(timezone.utc)
    warn_threshold = now + timedelta(days=warn_days)
    
    expiring = []
    
    for env in environments:
        # Extract expiration date - check multiple possible fields
        expiration_str = env.get("expirationDate") or env.get("properties", {}).get("expirationDate")
        
        if not expiration_str:
            logger.debug(f"Environment {env.get('name')} has no expiration date")
            continue
        
        expiration_date = parse_expiration_date(expiration_str)
        
        if not expiration_date:
            continue
        
        # Check if expired or expiring soon
        if expiration_date <= warn_threshold:
            days_until_expiration = (expiration_date - now).days
            
            status = "expired" if expiration_date < now else "expiring"
            
            expiring.append({
                "name": env.get("name"),
                "project": env.get("projectName"),
                "user": env.get("user") or env.get("properties", {}).get("user"),
                "catalogName": env.get("catalogName"),
                "environmentType": env.get("environmentType"),
                "resourceGroupId": env.get("resourceGroupId"),
                "expirationDate": expiration_date.isoformat(),
                "daysUntilExpiration": days_until_expiration,
                "status": status
            })
    
    logger.info(f"Found {len(expiring)} environments expiring within {warn_days} days")
    return expiring


def send_slack_notification(expiring_envs: List[Dict]) -> bool:
    """
    Send Slack notification about expiring environments.
    Uses webhook similar to aws_slack.py pattern.
    """
    webhook_url = os.environ.get("SLACK_WEBHOOK_URL")
    
    if not webhook_url:
        logger.warning("SLACK_WEBHOOK_URL not configured, skipping notification")
        return False
    
    # Check if we're in mock mode
    mock_mode = os.environ.get("SLACK_MOCK", "0") in ("1", "true", "True")
    
    if not expiring_envs:
        message = "✅ All Azure Deployment Environments are healthy - no expiration warnings."
        payload = {"text": message}
    else:
        # Build detailed message
        expired_count = sum(1 for e in expiring_envs if e["status"] == "expired")
        expiring_count = len(expiring_envs) - expired_count
        
        warning_emoji = "🚨" if expired_count > 0 else "⚠️"
        
        text = f"{warning_emoji} Azure Deployment Environment Expiration Alert"
        
        blocks = [
            {
                "type": "header",
                "text": {
                    "type": "plain_text",
                    "text": f"{warning_emoji} ADE Expiration Alert",
                    "emoji": True
                }
            },
            {
                "type": "section",
                "text": {
                    "type": "mrkdwn",
                    "text": f"*Summary:*\n• {expired_count} environment(s) already expired\n• {expiring_count} environment(s) expiring soon"
                }
            },
            {"type": "divider"}
        ]
        
        # Add details for each environment
        for env in expiring_envs[:10]:  # Limit to 10 to avoid message size limits
            days = env["daysUntilExpiration"]
            
            if env["status"] == "expired":
                status_text = f"❌ *EXPIRED* ({abs(days)} days ago)"
            elif days == 0:
                status_text = f"🚨 *Expires TODAY*"
            elif days == 1:
                status_text = f"⚠️ *Expires TOMORROW*"
            else:
                status_text = f"⏰ Expires in {days} days"
            
            blocks.append({
                "type": "section",
                "text": {
                    "type": "mrkdwn",
                    "text": (
                        f"{status_text}\n"
                        f"*Environment:* `{env['name']}`\n"
                        f"*Project:* {env['project']}\n"
                        f"*User:* {env.get('user', 'N/A')}\n"
                        f"*Expiration:* {env['expirationDate'][:10]}"
                    )
                }
            })
        
        if len(expiring_envs) > 10:
            blocks.append({
                "type": "context",
                "elements": [{
                    "type": "mrkdwn",
                    "text": f"_...and {len(expiring_envs) - 10} more environment(s)_"
                }]
            })
        
        payload = {
            "text": text,
            "blocks": blocks
        }
    
    # Mock mode or actual send
    if mock_mode:
        timestamp = datetime.utcnow().isoformat(timespec="seconds") + "Z"
        print(f"[MOCK-SLACK {timestamp}] {json.dumps(payload, ensure_ascii=False)}")
        return True
    
    try:
        response = requests.post(
            webhook_url,
            data=json.dumps(payload),
            headers={"Content-Type": "application/json"},
            timeout=10
        )
        response.raise_for_status()
        logger.info("Successfully sent Slack notification")
        return True
    except requests.exceptions.RequestException as e:
        logger.error(f"Failed to send Slack notification: {e}")
        return False


def main(mytimer: func.TimerRequest) -> None:
    """
    Timer-triggered function that runs daily to check for expiring ADE environments.
    
    Environment Variables Required:
    - ADE_SUBSCRIPTION_ID: Azure subscription ID
    - ADE_DEV_CENTER: DevCenter name
    - ADE_PROJECT_NAME: Project name
    - SLACK_WEBHOOK_URL: Slack webhook URL for notifications
    - EXPIRATION_WARN_DAYS: Days before expiration to warn (optional, default: 3)
    """
    utc_timestamp = datetime.utcnow().replace(tzinfo=timezone.utc).isoformat()
    
    if mytimer.past_due:
        logger.info('The timer is past due!')
    
    logger.info(f'Python timer trigger function ran at: {utc_timestamp}')
    
    try:
        # Get warning threshold from environment
        warn_days = int(os.environ.get("EXPIRATION_WARN_DAYS", "3"))
        
        # Check for expiring environments
        logger.info(f"Checking for environments expiring within {warn_days} days...")
        expiring_envs = check_expiring_environments(warn_days=warn_days)
        
        # Send Slack notification
        send_slack_notification(expiring_envs)
        
        logger.info(f"Successfully processed {len(expiring_envs)} expiring environment(s)")
        
    except Exception as e:
        logger.error(f"Error in expiration check: {str(e)}", exc_info=True)
        # Send error notification to Slack
        try:
            webhook_url = os.environ.get("SLACK_WEBHOOK_URL")
            if webhook_url:
                error_payload = {
                    "text": f"❌ ADE Expiration Check Failed",
                    "blocks": [{
                        "type": "section",
                        "text": {
                            "type": "mrkdwn",
                            "text": f"*Error:* {str(e)}\n*Time:* {utc_timestamp}"
                        }
                    }]
                }
                requests.post(webhook_url, json=error_payload, timeout=10)
        except:
            pass
        raise
