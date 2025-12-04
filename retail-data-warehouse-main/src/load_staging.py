import pandas as pd
import psycopg2
from config import get_db_connection_string

def load_excel_to_staging(file_path):
    """Load Excel data to staging table"""
    try:
        # Read Excel file
        df = pd.read_excel(file_path)
        print(f"Loaded {len(df)} rows from Excel")
        
        # Connect to database
        conn = psycopg2.connect(get_db_connection_string())
        cursor = conn.cursor()
        
        # Load to staging
        for _, row in df.iterrows():
            cursor.execute("""
                INSERT INTO staging.retail_sales_raw 
                VALUES (%s, %s, %s, %s, %s, %s, %s, %s)
            """, tuple(row))
        
        conn.commit()
        print("Data loaded to staging table")
        
    except Exception as e:
        print(f"Error: {e}")
        conn.rollback()
    finally:
        cursor.close()
        conn.close()