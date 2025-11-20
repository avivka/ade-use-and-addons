import datetime as dt
from shared.slack import post_to_slack
from shared.azure_env import iter_env_groups, parse_expires_on, delete_resource_group

WARN_DAYS = (7, 1)
TAG_OWNER = "ade:userUpn"
TAG_EXPIRES = "ade:expiresOn"

def run_once() -> int:
    today = dt.date.today()
    processed = 0
    for rg_name, tags in iter_env_groups(TAG_EXPIRES):
        processed += 1
        expires = parse_expires_on(tags.get(TAG_EXPIRES))
        owner = tags.get(TAG_OWNER, "unknown")
        if not expires:
            post_to_slack(f":warning: RG `{rg_name}` has invalid `{TAG_EXPIRES}`. Owner `{owner}`. Please fix.")
            continue

        days_left = (expires - today).days
        if days_left in WARN_DAYS:
            post_to_slack(
              f":alarm_clock: Env `{rg_name}` for `{owner}` expires in *{days_left}* day(s) on *{expires.isoformat()}*."
              " Consider extending or cleaning up."
            )
        elif days_left < 0:
            try:
                post_to_slack(f":no_entry: Env `{rg_name}` for `{owner}` expired on *{expires.isoformat()}*. Deleting...")
                delete_resource_group(rg_name)
                post_to_slack(f":wastebasket: Env `{rg_name}` for `{owner}` deleted.")
            except Exception as e:
                post_to_slack(f":x: Failed deleting `{rg_name}` (owner `{owner}`): {e}")
    return processed

# Timer binding entry
def main(timer) -> None:
    run_once()
