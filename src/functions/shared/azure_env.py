import os
import datetime as dt
from typing import Dict, Iterable, Tuple, Optional

from azure.identity import DefaultAzureCredential
from azure.mgmt.resource import ResourceManagementClient

DATE_FMT = "%Y-%m-%d"  # ISO-like (yyyy-mm-dd)

def _cred():
    return DefaultAzureCredential(exclude_interactive_browser_credential=True)

def resource_client():
    sub = os.environ["ADE_SUBSCRIPTION_ID"]
    return ResourceManagementClient(_cred(), sub)

def parse_expires_on(s: str) -> Optional[dt.date]:
    if not s:
        return None
    s = s.strip().split("T")[0]  # tolerate full ISO; keep date part
    try:
        return dt.datetime.strptime(s, DATE_FMT).date()
    except Exception:
        # fallback: try full ISO 8601
        try:
            return dt.datetime.fromisoformat(s).date()
        except Exception:
            return None

def iter_env_groups(tag_key="ade:expiresOn") -> Iterable[Tuple[str, Dict[str, str]]]:
    """Yield (resource_group_name, tags) for RGs carrying ADE tag."""
    client = resource_client()
    for rg in client.resource_groups.list():
        tags = rg.tags or {}
        if tag_key in tags:
            yield rg.name, tags

def delete_resource_group(rg_name: str) -> None:
    if os.environ.get("DRY_DELETE", "0") in ("1", "true", "True"):
        # pretend delete
        return
    from azure.mgmt.resource import ResourceManagementClient
    from .azure_env import _cred
    sub = os.environ["ADE_SUBSCRIPTION_ID"]
    client = ResourceManagementClient(_cred(), sub)
    poller = client.resource_groups.begin_delete(rg_name)
    poller.result()

