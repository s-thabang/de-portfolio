def load_fact_sales():
    """Load fact table with dimension keys"""
    cursor.execute("""
        INSERT INTO analytics.fact_sales (
            invoice_number, stock_code, customer_id, date_key,
            quantity, unit_price, line_total
        )
        SELECT 
            r.invoice,
            r.stock_code,
            r.customer_id,
            d.date_key,
            r.quantity,
            r.price,
            r.quantity * r.price
        FROM staging.retail_sales_raw r
        JOIN analytics.dim_date d ON r.invoice_date::date = d.invoice_date
        WHERE r.customer_id IS NOT NULL
    """)