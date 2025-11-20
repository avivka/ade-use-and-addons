import json, os
import azure.functions as func
from shared.slack import post_to_slack

def _fmt_money(x):
    try:
        return f"${float(x):.2f}"
    except Exception:
        return str(x)

def main(req: func.HttpRequest) -> func.HttpResponse:
    # Payload is Azure Monitor "Common Alert Schema" from a Budget notification via Action Group
    try:
        body = req.get_json()
    except ValueError:
        return func.HttpResponse("invalid json", status_code=400)

    # In Common Alert Schema, budget data arrives under data.essentials + data.alertContext
    essentials = body.get("data", {}).get("essentials", {})
    ctx = body.get("data", {}).get("alertContext", {})
    # Fallbacks for different schema variants:
    threshold = ctx.get("threshold", essentials.get("severity"))
    budget_name = ctx.get("budgetName") or essentials.get("alertRule")
    current_spend = ctx.get("currentSpend", {}).get("amount") or ctx.get("currentCost")
    unit = (ctx.get("currentSpend", {}) or {}).get("unit") or "USD"
    time_period = ctx.get("timeGrain") or "Monthly"

    # Try to pull custom tags passed into budget name/filters (you filtered by tag 'ade:userUpn:...')
    user_upn = None
    for k in ("dimensions", "dimensionsFilter", "criteria"):
        dims = ctx.get(k)
        if isinstance(dims, dict):
            for dk, dv in dims.items():
                if isinstance(dv, str) and dv.startswith("ade:userUpn:"):
                    user_upn = dv.split(":", 2)[-1]
        elif isinstance(dims, list):
            for d in dims:
                v = (d.get("value") if isinstance(d, dict) else None)
                if isinstance(v, str) and v.startswith("ade:userUpn:"):
                    user_upn = v.split(":", 2)[-1]

    threshold_str = f"{threshold}%" if threshold is not None else "Threshold"
    who = f"`{user_upn}`" if user_upn else "*unknown user*"

    text = (
        f":warning: Budget alert at *{threshold_str}* for {who}\n"
        f"• Budget: *{budget_name or 'n/a'}*\n"
        f"• Period: {time_period}\n"
        f"• Current spend: {_fmt_money(current_spend)} {unit}\n"
        f"• Cap: $200.00 USD"
    )

    try:
        post_to_slack(text)
    except Exception as e:
        return func.HttpResponse(f"slack post failed: {e}", status_code=500)

    return func.HttpResponse("ok", status_code=200)
