# Comprehensive Analytics Test
# Runs all business questions and saves results

set -e

echo "Starting Comprehensive Analytics Test Suite"
echo "=============================================="
echo ""

# Create results directory
RESULTS_DIR="../analytics_results"
mkdir -p $RESULTS_DIR
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
REPORT_FILE="$RESULTS_DIR/analytics_report_${TIMESTAMP}.txt"

# Initialize report
cat > $REPORT_FILE << 'HEADER'
╔══════════════════════════════════════════════════════════════╗
║     OLIST E-COMMERCE DATA ANALYTICS REPORT                   ║
║     Serverless Data Pipeline Portfolio Project               ║
╚══════════════════════════════════════════════════════════════╝

Generated: $(date)
Database: olist-pipeline_db
Region: af-south-1

HEADER

echo "Report will be saved to: $REPORT_FILE"
echo ""

# Function to run query and append to report
run_query() {
    local query_name="$1"
    local query="$2"
    local description="$3"
    
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" >> $REPORT_FILE
    echo "QUERY: $query_name" >> $REPORT_FILE
    echo "DESCRIPTION: $description" >> $REPORT_FILE
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" >> $REPORT_FILE
    echo "" >> $REPORT_FILE
    
    echo "Running: $query_name"
    
    # Get database and workgroup from Terraform
    cd ../terraform
    DATABASE_NAME=$(terraform output -raw glue_database_name)
    WORKGROUP=$(terraform output -raw athena_workgroup_name)
    cd ../scripts
    
    # Start query execution
    EXECUTION_ID=$(aws athena start-query-execution \
        --query-string "$query" \
        --query-execution-context Database=$DATABASE_NAME \
        --work-group $WORKGROUP \
        --region af-south-1 \
        --query 'QueryExecutionId' \
        --output text)
    
    # Wait for completion
    while true; do
        STATUS=$(aws athena get-query-execution \
            --query-execution-id $EXECUTION_ID \
            --region af-south-1 \
            --query 'QueryExecution.Status.State' \
            --output text)
        
        if [ "$STATUS" = "SUCCEEDED" ]; then
            break
        elif [ "$STATUS" = "FAILED" ] || [ "$STATUS" = "CANCELLED" ]; then
            echo "  Failed" >> $REPORT_FILE
            echo "  Failed"
            echo "" >> $REPORT_FILE
            return
        fi
        sleep 2
    done
    
    # Get results
    aws athena get-query-results \
        --query-execution-id $EXECUTION_ID \
        --region af-south-1 \
        --output text >> $REPORT_FILE
    
    echo "" >> $REPORT_FILE
    echo "  Complete"
    echo ""
}

# ============================================
# BUSINESS QUESTION 1: Dataset Overview
# ============================================
run_query \
    "Q1: Dataset Overview" \
    "SELECT 'Orders' as entity, COUNT(*) as count FROM olist_orders_dataset
     UNION ALL
     SELECT 'Customers', COUNT(*) FROM olist_customers_dataset
     UNION ALL
     SELECT 'Products', COUNT(*) FROM olist_products_dataset
     UNION ALL
     SELECT 'Sellers', COUNT(*) FROM olist_sellers_dataset
     UNION ALL
     SELECT 'Order Items', COUNT(*) FROM olist_order_items_dataset
     UNION ALL
     SELECT 'Reviews', COUNT(*) FROM olist_order_reviews_dataset" \
    "Total records across all tables"

# ============================================
# BUSINESS QUESTION 2: Order Status Distribution
# ============================================
run_query \
    "Q2: Order Status Distribution" \
    "SELECT 
        order_status,
        COUNT(*) as order_count,
        ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM olist_orders_dataset), 2) as percentage
     FROM olist_orders_dataset
     GROUP BY order_status
     ORDER BY order_count DESC" \
    "Breakdown of order statuses (delivered, canceled, etc.)"

# ============================================
# BUSINESS QUESTION 3: Revenue by Product Category (Top 10)
# ============================================
run_query \
    "Q3: Top 10 Revenue-Generating Categories" \
    "SELECT 
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
     LIMIT 10" \
    "Which product categories generate the most revenue?"

# ============================================
# BUSINESS QUESTION 4: Customer Distribution by State
# ============================================
run_query \
    "Q4: Top 10 States by Customer Count" \
    "SELECT 
        customer_state,
        COUNT(*) as customer_count,
        ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM olist_customers_dataset), 2) as percentage
     FROM olist_customers_dataset
     GROUP BY customer_state
     ORDER BY customer_count DESC
     LIMIT 10" \
    "Geographic distribution of customers"

# ============================================
# BUSINESS QUESTION 5: Payment Method Analysis
# ============================================
run_query \
    "Q5: Payment Method Performance" \
    "SELECT 
        payment_type,
        COUNT(DISTINCT order_id) as total_orders,
        ROUND(SUM(payment_value), 2) as total_revenue,
        ROUND(AVG(payment_value), 2) as avg_order_value,
        ROUND(AVG(payment_installments), 1) as avg_installments
     FROM olist_order_payments_dataset
     GROUP BY payment_type
     ORDER BY total_revenue DESC" \
    "How do customers prefer to pay? Revenue by payment method"

# ============================================
# BUSINESS QUESTION 6: Customer Satisfaction (Reviews)
# ============================================
run_query \
    "Q6: Review Score Distribution (Customer Satisfaction)" \
    "SELECT 
        review_score,
        COUNT(*) as review_count,
        ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM olist_order_reviews_dataset), 2) as percentage,
        CASE 
            WHEN review_score >= 4 THEN 'Positive'
            WHEN review_score = 3 THEN 'Neutral'
            ELSE 'Negative'
        END as sentiment
     FROM olist_order_reviews_dataset
     GROUP BY review_score
     ORDER BY review_score DESC" \
    "What's our customer satisfaction level?"

# ============================================
# BUSINESS QUESTION 7: Delivery Performance
# ============================================
run_query \
    "Q7: On-Time Delivery Rate" \
    "SELECT 
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
         END" \
    "What percentage of orders are delivered on time?"

# ============================================
# BUSINESS QUESTION 8: Seller Performance by State
# ============================================
run_query \
    "Q8: Top 10 States by Seller Performance" \
    "SELECT 
        s.seller_state,
        COUNT(DISTINCT s.seller_id) as seller_count,
        COUNT(DISTINCT oi.order_id) as total_orders,
        ROUND(SUM(oi.price), 2) as total_revenue
     FROM olist_sellers_dataset s
     JOIN olist_order_items_dataset oi ON s.seller_id = oi.seller_id
     GROUP BY s.seller_state
     ORDER BY total_revenue DESC
     LIMIT 10" \
    "Which states have the most successful sellers?"

# ============================================
# BUSINESS QUESTION 9: Customer Retention
# ============================================
run_query \
    "Q9: Customer Retention (Repeat Purchase Rate)" \
    "SELECT 
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
     ORDER BY customer_count DESC" \
    "How many customers make repeat purchases?"

# ============================================
# BUSINESS QUESTION 10: Executive Dashboard KPIs
# ============================================
run_query \
    "Q10: Executive Dashboard - Key Metrics" \
    "SELECT 'Total Orders' as metric, CAST(COUNT(*) as VARCHAR) as value FROM olist_orders_dataset
     UNION ALL
     SELECT 'Total Revenue (BRL)', CAST(ROUND(SUM(payment_value), 2) as VARCHAR) FROM olist_order_payments_dataset
     UNION ALL
     SELECT 'Average Order Value (BRL)', CAST(ROUND(AVG(payment_value), 2) as VARCHAR) FROM olist_order_payments_dataset
     UNION ALL
     SELECT 'Unique Customers', CAST(COUNT(DISTINCT customer_id) as VARCHAR) FROM olist_customers_dataset
     UNION ALL
     SELECT 'Unique Sellers', CAST(COUNT(*) as VARCHAR) FROM olist_sellers_dataset
     UNION ALL
     SELECT 'Total Products', CAST(COUNT(*) as VARCHAR) FROM olist_products_dataset
     UNION ALL
     SELECT 'Average Review Score', CAST(ROUND(AVG(review_score), 2) as VARCHAR) FROM olist_order_reviews_dataset
     UNION ALL
     SELECT 'Delivery Success Rate %', CAST(ROUND(SUM(CASE WHEN order_status = 'delivered' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) as VARCHAR) FROM olist_orders_dataset" \
    "High-level KPIs for executive summary"

# ============================================
# SUMMARY
# ============================================
echo "" >> $REPORT_FILE
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" >> $REPORT_FILE
echo "END OF REPORT" >> $REPORT_FILE
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" >> $REPORT_FILE

echo ""
echo "Analytics test suite completed!"
echo ""
echo "Full report saved to: $REPORT_FILE"
echo ""
echo "You can view it with:"
echo "  cat $REPORT_FILE"
echo "  or"
echo "  open $REPORT_FILE"
echo ""
echo "Summary:"
echo "  - 10 business questions answered"
echo "  - Results saved in text format"
echo "  - Ready for portfolio documentation"
