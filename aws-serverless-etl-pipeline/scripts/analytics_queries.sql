-- ============================================
-- Olist E-Commerce Analytics Queries
-- Portfolio Project: Serverless Data Pipeline
-- ============================================

-- Query 1: Dataset Overview
SELECT 'Orders' as metric, COUNT(*) as value FROM olist_orders_dataset
UNION ALL
SELECT 'Customers', COUNT(*) FROM olist_customers_dataset
UNION ALL
SELECT 'Products', COUNT(*) FROM olist_products_dataset
UNION ALL
SELECT 'Sellers', COUNT(*) FROM olist_sellers_dataset;

-- Query 2: Order Status Distribution
SELECT 
    order_status,
    COUNT(*) as order_count,
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM olist_orders_dataset), 2) as percentage
FROM olist_orders_dataset
GROUP BY order_status
ORDER BY order_count DESC;

-- Query 3: Top 10 States by Customer Count
SELECT 
    customer_state,
    COUNT(*) as customer_count
FROM olist_customers_dataset
GROUP BY customer_state
ORDER BY customer_count DESC
LIMIT 10;

-- Query 4: Payment Type Analysis
SELECT 
    payment_type,
    COUNT(*) as transactions,
    ROUND(SUM(payment_value), 2) as total_revenue
FROM olist_order_payments_dataset
GROUP BY payment_type
ORDER BY total_revenue DESC;

-- Query 5: Product Category Popularity
SELECT 
    product_category_name,
    COUNT(*) as product_count
FROM olist_products_dataset
WHERE product_category_name IS NOT NULL
GROUP BY product_category_name
ORDER BY product_count DESC
LIMIT 10;

-- Query 6: Review Score Distribution
SELECT 
    review_score,
    COUNT(*) as review_count,
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM olist_order_reviews_dataset), 2) as percentage
FROM olist_order_reviews_dataset
GROUP BY review_score
ORDER BY review_score DESC;

-- Query 7: Average Order Value by Payment Type
SELECT 
    payment_type,
    COUNT(DISTINCT order_id) as orders,
    ROUND(AVG(payment_value), 2) as avg_value,
    ROUND(AVG(payment_installments), 1) as avg_installments
FROM olist_order_payments_dataset
GROUP BY payment_type
ORDER BY avg_value DESC;

-- Query 8: Seller Performance (Top 10)
SELECT 
    seller_state,
    COUNT(DISTINCT seller_id) as seller_count,
    COUNT(*) as items_sold
FROM olist_sellers_dataset s
JOIN olist_order_items_dataset oi ON s.seller_id = oi.seller_id
GROUP BY seller_state
ORDER BY items_sold DESC
LIMIT 10;
