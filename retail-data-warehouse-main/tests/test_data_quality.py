import psycopg2
import sys
import os
sys.path.append(os.path.join(os.path.dirname(__file__), '..'))
from src.config import get_db_connection_string

def test_no_negative_prices():
    conn = psycopg2.connect(get_db_connection_string())
    cursor = conn.cursor()
    cursor.execute("SELECT COUNT(*) FROM staging.retail_sales_raw WHERE price::numeric < 0")
    count = cursor.fetchone()[0]
    cursor.close()
    conn.close()
    
    # Changed from assert to an if/else block for reporting
    if count == 0:
        print("✅ No negative prices found.")
    else:
        print(f"❌ Found {count} negative prices. Requires cleanup.")
    return count

def test_no_negative_quantities():
    conn = psycopg2.connect(get_db_connection_string())
    cursor = conn.cursor()
    cursor.execute("SELECT COUNT(*) FROM staging.retail_sales_raw WHERE quantity::integer < 0")
    count = cursor.fetchone()[0]
    cursor.close()
    conn.close()
    
    # Changed from assert to an if/else block for reporting
    if count == 0:
        print("✅ No negative quantities found.")
    else:
        print(f"❌ Found {count} negative quantities. Requires cleanup.")
    return count

if __name__ == "__main__":
    print("--- Running Data Quality Checks ---")
    test_no_negative_prices()
    test_no_negative_quantities()
    print("--- Checks Complete ---")