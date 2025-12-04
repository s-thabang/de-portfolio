-- 1. Revenue Metrics
CREATE OR REPLACE VIEW analytics.vw_daily_revenue AS
SELECT
    DATE(invoice_date) as sale_date,
    SUM(quantity * price) as daily_revenue,
    COUNT(DISTINCT invoice) as daily_orders,
    COUNT(DISTINCT customer_id) as daily_customers
FROM staging.retail_sales_raw
GROUP BY
    DATE(invoice_date);

-- 2. Customer Analytics
CREATE OR REPLACE VIEW analytics.vw_customer_summary AS
SELECT
    customer_id,
    country,
    COUNT(DISTINCT invoice) as total_orders,
    SUM(quantity * price) as total_spent,
    MIN(invoice_date) as first_purchase,
    MAX(invoice_date) as last_purchase
FROM staging.retail_sales_raw
WHERE
    customer_id IS NOT NULL
GROUP BY
    customer_id,
    country;

-- 3. Product Performance
CREATE OR REPLACE VIEW analytics.vw_product_performance AS
SELECT
    stock_code,
    description,
    COUNT(DISTINCT invoice) as times_ordered,
    SUM(quantity) as total_quantity,
    SUM(quantity * price) as total_revenue,
    AVG(price) as avg_price
FROM staging.retail_sales_raw
GROUP BY
    stock_code,
    description;

-- 4. Return Analysis
CREATE OR REPLACE VIEW analytics.vw_returns_analysis AS
SELECT
    stock_code,
    description,
    COUNT(*) as return_count,
    SUM(quantity) as total_returned_quantity,
    SUM(quantity * price) as total_refund_amount
FROM staging.retail_sales_raw
WHERE
    quantity < 0
GROUP BY
    stock_code,
    description;

-- 5. Regional Performance
CREATE OR REPLACE VIEW analytics.vw_regional_performance AS
SELECT
    country,
    COUNT(DISTINCT customer_id) as total_customers,
    COUNT(DISTINCT invoice) as total_orders,
    SUM(quantity * price) as total_revenue,
    CASE
        WHEN SUM(quantity * price) = (
            SELECT MAX(region_revenue)
            FROM (
                    SELECT country, SUM(quantity * price) as region_revenue
                    FROM staging.retail_sales_raw
                    GROUP BY
                        country
                ) regions
        ) THEN 'TOP PERFORMING'
        ELSE 'OTHER'
    END as performance_rank
FROM staging.retail_sales_raw
GROUP BY
    country
ORDER BY total_revenue DESC;

-- 6. Monthly Regional Sales
CREATE OR REPLACE VIEW analytics.vw_monthly_regional_sales AS
SELECT
    country,
    DATE_TRUNC ('month', invoice_date) as sale_month,
    SUM(quantity * price) as monthly_revenue,
    RANK() OVER (
        PARTITION BY
            DATE_TRUNC ('month', invoice_date)
        ORDER BY SUM(quantity * price) DESC
    ) as region_rank
FROM staging.retail_sales_raw
GROUP BY
    country,
    DATE_TRUNC ('month', invoice_date);