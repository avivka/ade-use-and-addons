import os, json, requests, sys, datetime as dt

def post_to_slack(text: str, blocks=None):
    url = os.environ.get("SLACK_WEBHOOK_URL")
    mock = os.environ.get("SLACK_MOCK", "0") in ("1", "true", "True")
    payload = {"text": text}
    if blocks:
        payload["blocks"] = blocks

    if mock or not url:
        # Mocked "Slack" → print deterministic line we can grep in demo
        stamp = dt.datetime.utcnow().isoformat(timespec="seconds") + "Z"
        sys.stdout.write(f"[MOCK-SLACK {stamp}] {json.dumps(payload, ensure_ascii=False)}\n")
        sys.stdout.flush()
        return

    resp = requests.post(url, data=json.dumps(payload), headers={"Content-Type": "application/json"})
    resp.raise_for_status()
