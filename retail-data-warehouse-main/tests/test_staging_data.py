import psycopg2
import csv
import sys
import os

sys.path.append(os.path.join(os.path.dirname(__file__), '..'))

from src.config import get_db_connection_string

def test_staging_has_data():
    """Test if staging table has data loaded"""
    try:
        conn = psycopg2.connect(get_db_connection_string())
        cursor = conn.cursor()
        
        cursor.execute("SELECT COUNT(*) FROM staging.retail_sales_raw")
        staging_count = cursor.fetchone()[0]
        
        print(f"Staging table has {staging_count} rows")
        
        if staging_count == 0:
            print("No data in staging table")
            return False
        else:
            print("Staging table has data")
            return True
            
    except Exception as e:
        print(f"Test failed: {e}")
        return False
    finally:
        cursor.close()
        conn.close()

def load_csv_to_staging_if_empty():
    """Load CSV using native Python csv module"""
    conn = psycopg2.connect(get_db_connection_string())
    cursor = conn.cursor()
    
    cursor.execute("SELECT COUNT(*) FROM staging.retail_sales_raw")
    if cursor.fetchone()[0] == 0:
        print("Loading CSV data to staging...")
        
        with open('YOUR-FILE-PATH', 'r') as f:
            reader = csv.reader(f)
            next(reader) 
            
            for row in reader: 
                cleaned_row = [value if value != '' else None for value in row]
               

                cursor.execute("""
                    INSERT INTO staging.retail_sales_raw 
                    VALUES (%s, %s, %s, %s, %s, %s, %s, %s)
                """, cleaned_row)
        
        conn.commit()
        print("CSV data loaded to staging")
    else:
        print("Staging already has data")
    
    cursor.close()
    conn.close()

if __name__ == "__main__":
    load_csv_to_staging_if_empty()
    test_staging_has_data()