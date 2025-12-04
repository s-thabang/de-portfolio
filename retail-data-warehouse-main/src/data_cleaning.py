def clean_staging_data():
    """Clean data in staging table"""
    conn = psycopg2.connect(get_db_connection_string())
    cursor = conn.cursor()
    
    # Remove completely empty rows
    cursor.execute("""
        DELETE FROM staging.retail_sales_raw 
        WHERE invoice IS NULL AND stock_code IS NULL
    """)
    
    # Handle negative quantities (returns)
    cursor.execute("""
        UPDATE staging.retail_sales_raw 
        SET quantity = ABS(quantity) 
        WHERE quantity < 0
    """)
    
    # Remove zero/negative prices
    cursor.execute("""
        DELETE FROM staging.retail_sales_raw 
        WHERE price <= 0
    """)
    
    conn.commit()
    print("Data cleaning completed")