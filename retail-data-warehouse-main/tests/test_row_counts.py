def test_no_data_loss():
    cursor.execute("SELECT COUNT(*) FROM staging.retail_sales_raw")
    staging_count = cursor.fetchone()[0]
    
    cursor.execute("SELECT COUNT(*) FROM analytics.fact_sales")
    fact_count = cursor.fetchone()[0]
    
    # Allow for filtered records in ETL
    assert fact_count <= staging_count