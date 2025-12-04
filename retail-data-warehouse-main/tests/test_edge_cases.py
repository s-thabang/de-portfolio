def test_null_handling():
    cursor.execute("""
        SELECT COUNT(*) FROM staging.retail_sales_raw 
        WHERE invoice IS NULL OR stock_code IS NULL
    """)
    null_count = cursor.fetchone()[0]
    print(f"Records with null key fields: {null_count}")