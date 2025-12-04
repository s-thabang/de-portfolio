def load_dim_customers():
    """Extract unique customers from staging"""
    cursor.execute("""
        INSERT INTO analytics.dim_customer (customer_id, country)
        SELECT DISTINCT customer_id, country 
        FROM staging.retail_sales_raw 
        WHERE customer_id IS NOT NULL
    """)