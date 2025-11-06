import azure.functions as func
from src.functions.expirationSweep.__init__ import run_once  # re-use logic

def main(req: func.HttpRequest) -> func.HttpResponse:
    try:
        ran = run_once()
        return func.HttpResponse(f"expiration sweep ok; processed={ran}", status_code=200)
    except Exception as e:
        return func.HttpResponse(f"error: {e}", status_code=500)
