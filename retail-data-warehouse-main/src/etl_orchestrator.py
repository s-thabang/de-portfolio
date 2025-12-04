import logging
from load_staging import load_excel_to_staging
from data_cleaning import clean_staging_data
from load_dimensions import load_all_dimensions
from load_facts import load_fact_sales
from etl_logger import log_etl_step

def run_etl_pipeline(excel_file_path):
    """Main ETL orchestration function"""
    try:
        # Step 1: Data Ingestion
        load_excel_to_staging(excel_file_path)
        log_etl_step("Data Ingestion", True)
        
        # Step 2: Data Cleaning
        clean_staging_data()
        log_etl_step("Data Cleaning", True)
        
        # Step 3: Dimension Loading
        load_all_dimensions()
        log_etl_step("Dimension Loading", True)
        
        # Step 4: Fact Table Loading
        load_fact_sales()
        log_etl_step("Fact Table Loading", True)
        
        print("ETL Pipeline Completed Successfully")
        
    except Exception as e:
        logging.error(f"ETL Pipeline Failed: {e}")
        print(f"ETL Pipeline Failed: {e}")

if __name__ == "__main__":
    run_etl_pipeline("data/raw/online_retail_ll.xlsx")