import azure.functions as func

app = func.FunctionApp()

@app.timer_trigger(schedule="0 9 * * *", arg_name="myTimer", run_on_startup=False)
def test_timer(myTimer: func.TimerRequest) -> None:
    """Minimal test function."""
    import logging
    logging.info('Test function executed')
    if myTimer.past_due:
        logging.info('Timer is past due!')
