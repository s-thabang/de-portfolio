#!/bin/bash

echo "╔══════════════════════════════════════════════════════════════╗"
echo "║          QUICK STATS - EXECUTIVE DASHBOARD                   ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

cd ../terraform
DATABASE=$(terraform output -raw glue_database_name)
WORKGROUP=$(terraform output -raw athena_workgroup_name)
cd ../scripts

QUERY="
SELECT 'Total Orders' as metric, CAST(COUNT(*) as VARCHAR) as value FROM olist_orders_dataset
UNION ALL
SELECT 'Total Revenue (BRL)', CAST(ROUND(SUM(payment_value), 2) as VARCHAR) FROM olist_order_payments_dataset
UNION ALL
SELECT 'Avg Order Value (BRL)', CAST(ROUND(AVG(payment_value), 2) as VARCHAR) FROM olist_order_payments_dataset
UNION ALL
SELECT 'Unique Customers', CAST(COUNT(DISTINCT customer_id) as VARCHAR) FROM olist_customers_dataset
UNION ALL
SELECT 'Unique Sellers', CAST(COUNT(*) as VARCHAR) FROM olist_sellers_dataset
UNION ALL
SELECT 'Avg Review Score', CAST(ROUND(AVG(review_score), 2) as VARCHAR) FROM olist_order_reviews_dataset
UNION ALL
SELECT 'Delivered Orders %', CAST(ROUND(SUM(CASE WHEN order_status = 'delivered' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) as VARCHAR) FROM olist_orders_dataset
"

echo "Running executive dashboard query..."
echo ""

EXECUTION_ID=$(aws athena start-query-execution \
    --query-string "$QUERY" \
    --query-execution-context Database=$DATABASE \
    --work-group $WORKGROUP \
    --region af-south-1 \
    --query 'QueryExecutionId' \
    --output text)

# Wait
sleep 5

# Display results
aws athena get-query-results \
    --query-execution-id $EXECUTION_ID \
    --region af-south-1 \
    --query 'ResultSet.Rows[*].Data[*].VarCharValue' \
    --output table

echo ""
echo "Dashboard complete!"
