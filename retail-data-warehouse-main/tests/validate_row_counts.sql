
SELECT 'staging' as table_name, COUNT(*) as row_count
FROM staging.retail_sales_raw
UNION ALL
SELECT 'fact_sales', COUNT(*)
FROM analytics.fact_sales;