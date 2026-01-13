-- ============================================
-- Advanced Analytics Queries
-- Olist E-Commerce Portfolio Project
-- ============================================

-- KPI 1: Revenue by Product Category (Top 10)
-- Shows which product categories drive the most revenue
SELECT 
    COALESCE(t.product_category_name_english, 'Unknown') as category,
    COUNT(DISTINCT oi.order_id) as total_orders,
    ROUND(SUM(oi.price), 2) as total_revenue,
    ROUND(AVG(oi.price), 2) as avg_price
FROM olist_order_items_dataset oi
JOIN olist_products_dataset p ON oi.product_id = p.product_id
LEFT JOIN product_category_name_translation t 
    ON p.product_category_name = t.product_category_name
GROUP BY t.product_category_name_english
ORDER BY total_revenue DESC
LIMIT 10;


-- KPI 2: Delivery Performance
-- Calculates on-time vs late delivery rate
SELECT 
    CASE 
        WHEN order_delivered_customer_date <= order_estimated_delivery_date 
        THEN 'On Time'
        ELSE 'Late'
    END as delivery_status,
    COUNT(*) as order_count,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2) as percentage
FROM olist_orders_dataset
WHERE order_status = 'delivered'
    AND order_delivered_customer_date IS NOT NULL
    AND order_estimated_delivery_date IS NOT NULL
GROUP BY 
    CASE 
        WHEN order_delivered_customer_date <= order_estimated_delivery_date 
        THEN 'On Time'
        ELSE 'Late'
    END;


-- KPI 3: Customer Satisfaction (NPS-style)
-- Analyzes review scores to calculate satisfaction metrics
SELECT 
    review_score,
    COUNT(*) as review_count,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2) as percentage,
    CASE 
        WHEN review_score >= 4 THEN 'Positive'
        WHEN review_score = 3 THEN 'Neutral'
        ELSE 'Negative'
    END as sentiment
FROM olist_order_reviews_dataset
GROUP BY review_score
ORDER BY review_score DESC;


-- KPI 4: Geographic Revenue Distribution
-- Shows revenue by state to identify key markets
SELECT 
    c.customer_state,
    COUNT(DISTINCT o.order_id) as total_orders,
    ROUND(SUM(p.payment_value), 2) as total_revenue,
    ROUND(AVG(p.payment_value), 2) as avg_order_value
FROM olist_customers_dataset c
JOIN olist_orders_dataset o ON c.customer_id = o.customer_id
JOIN olist_order_payments_dataset p ON o.order_id = p.order_id
WHERE o.order_status = 'delivered'
GROUP BY c.customer_state
ORDER BY total_revenue DESC
LIMIT 10;


-- KPI 5: Seller Performance Ranking
-- Identifies top-performing sellers by revenue and volume
SELECT 
    s.seller_id,
    s.seller_state,
    s.seller_city,
    COUNT(DISTINCT oi.order_id) as total_orders,
    COUNT(oi.order_item_id) as items_sold,
    ROUND(SUM(oi.price), 2) as total_revenue,
    ROUND(AVG(oi.price), 2) as avg_item_price
FROM olist_sellers_dataset s
JOIN olist_order_items_dataset oi ON s.seller_id = oi.seller_id
GROUP BY s.seller_id, s.seller_state, s.seller_city
ORDER BY total_revenue DESC
LIMIT 20;


-- KPI 6: Payment Method Analysis
-- Compares payment methods by volume and value
SELECT 
    payment_type,
    COUNT(DISTINCT order_id) as total_orders,
    ROUND(SUM(payment_value), 2) as total_revenue,
    ROUND(AVG(payment_value), 2) as avg_order_value,
    ROUND(AVG(payment_installments), 1) as avg_installments
FROM olist_order_payments_dataset
GROUP BY payment_type
ORDER BY total_revenue DESC;


-- KPI 7: Customer Retention / Repeat Purchase Rate
-- Analyzes how many customers make repeat purchases
SELECT 
    order_count_bucket,
    COUNT(*) as customer_count,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2) as percentage
FROM (
    SELECT 
        customer_id,
        CASE 
            WHEN COUNT(order_id) = 1 THEN '1 order (New)'
            WHEN COUNT(order_id) = 2 THEN '2 orders (Returning)'
            WHEN COUNT(order_id) >= 3 THEN '3+ orders (Loyal)'
        END as order_count_bucket
    FROM olist_orders_dataset
    GROUP BY customer_id
)
GROUP BY order_count_bucket
ORDER BY customer_count DESC;


-- EXECUTIVE DASHBOARD QUERY
-- Single query for high-level metrics
SELECT 
    'Total Orders' as metric,
    CAST(COUNT(*) as VARCHAR) as value
FROM olist_orders_dataset

UNION ALL

SELECT 
    'Total Revenue (BRL)',
    CAST(ROUND(SUM(payment_value), 2) as VARCHAR)
FROM olist_order_payments_dataset

UNION ALL

SELECT 
    'Average Order Value (BRL)',
    CAST(ROUND(AVG(payment_value), 2) as VARCHAR)
FROM olist_order_payments_dataset

UNION ALL

SELECT 
    'Unique Customers',
    CAST(COUNT(DISTINCT customer_id) as VARCHAR)
FROM olist_customers_dataset

UNION ALL

SELECT 
    'Unique Sellers',
    CAST(COUNT(*) as VARCHAR)
FROM olist_sellers_dataset

UNION ALL

SELECT 
    'Average Review Score',
    CAST(ROUND(AVG(review_score), 2) as VARCHAR)
FROM olist_order_reviews_dataset;
