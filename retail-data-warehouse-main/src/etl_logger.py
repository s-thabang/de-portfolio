import logging

logging.basicConfig(
    filename='logs/etl_pipeline.log',
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s'
)

def log_etl_step(step_name, success, records_processed=0):
    if success:
        logging.info(f"{step_name}: SUCCESS - {records_processed} records")
    else:
        logging.error(f"{step_name}: FAILED")