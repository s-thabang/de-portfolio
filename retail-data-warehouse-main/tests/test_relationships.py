def test_all_facts_have_dimensions():
    cursor.execute("""
        SELECT COUNT(*) FROM analytics.fact_sales f
        LEFT JOIN analytics.dim_customer c ON f.customer_id = c.customer_id
        WHERE c.customer_id IS NULL
    """)
    assert cursor.fetchone()[0] == 0