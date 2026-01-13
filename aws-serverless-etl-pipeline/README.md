## Project Overview

This project demonstrates data engineering practices using AWS serverless services to build a cost-effective, scalable analytics platform. The pipeline ingests raw CSV data, transforms it to columnar Parquet format, catalogs schemas automatically, and enables SQL-based analytics—all within AWS Free Tier limits.

**Dataset:** [Olist Brazilian E-Commerce](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce) (100K orders, 9 tables, ~120MB)

**Business Context:** E-commerce marketplace analytics enabling stakeholders to query order performance, customer behavior, seller metrics, and delivery KPIs through SQL without engineering intervention.

## Architecture
```
Local CSV Files → S3 Raw Bucket → Lambda (CSV→Parquet) → S3 Processed Bucket
                                                              ↓
                                                        Glue Crawler
                                                              ↓
                                                      Glue Data Catalog
                                                              ↓
                                                    Athena (SQL Queries)
```

**Key Design Decisions:**
- **Serverless-first:** Zero infrastructure management, pay-per-use pricing
- **Batch processing:** Scheduled/manual triggers (vs. streaming for cost efficiency)
- **Columnar storage:** Parquet with Snappy compression (75-85% size reduction)
- **Schema-on-read:** Glue Crawler auto-discovers schemas from Parquet metadata
- **IaC-only:** 100% Terraform deployment, zero console click-ops

## Tech Stack

| Component | Technology | Purpose |
|-----------|------------|---------|
| **Storage** | S3 | Raw CSV & processed Parquet data lakes |
| **Compute** | Lambda (Python 3.11) | Stateless CSV-to-Parquet transformation |
| **Orchestration** | Manual invocation | Cost-optimized for portfolio demo |
| **Catalog** | Glue Data Catalog | Centralized metadata repository |
| **Schema Discovery** | Glue Crawler | Automated table creation from Parquet |
| **Analytics** | Athena | Serverless SQL query engine |
| **IaC** | Terraform | Infrastructure as Code |
| **Dependencies** | AWS Data Wrangler Layer | pandas + pyarrow without packaging overhead |

## Key Features

### Data Engineering Best Practices
**Infrastructure as Code** - Entire stack deployed via Terraform  
**Idempotent transformations** - Lambda functions can be re-run safely  
**Data quality checks** - Null value detection, row count validation  
**Partitioned storage** - Files organized by table name for performance  
**Compression optimization** - Snappy compression balances speed/size  
**Cost monitoring** - Query execution metrics tracked in Athena  

### Production-Ready Components
- **Error handling:** Try-catch blocks with detailed CloudWatch logging
- **Scalability:** Lambda auto-scales to process multiple files concurrently
- **Security:** S3 bucket encryption, IAM least-privilege policies, no public access
- **Monitoring:** CloudWatch Logs with 7-day retention
- **Teardown automation:** One-command infrastructure destruction

## Quick Start

### Prerequisites
```bash
# macOS/Linux required
aws --version        # AWS CLI v2
terraform --version  # Terraform ≥1.0
python3 --version    # Python 3.11+
```

### Deployment
```bash
# 1. Clone and configure
git clone <repo-url>
cd olist-serverless-data-pipeline
aws configure  # Set region: af-south-1

# 2. Deploy infrastructure
cd terraform
terraform init
terraform apply  # Creates 21 resources in ~60s

# 3. Upload data and transform
cd ../scripts
./upload_data_to_s3.sh          # Upload CSVs to S3
./transform_all_csvs.sh         # Invoke Lambda for all files (~2 min)

# 4. Catalog and query
aws glue start-crawler --name olist-pipeline-crawler --region af-south-1
./run_athena_query.sh "SELECT * FROM olist_orders_dataset LIMIT 10"
```

## Sample Analytics Queries

### Revenue by Product Category
```sql
SELECT 
    t.product_category_name_english as category,
    ROUND(SUM(oi.price), 2) as revenue,
    COUNT(DISTINCT oi.order_id) as orders
FROM olist_order_items_dataset oi
JOIN olist_products_dataset p ON oi.product_id = p.product_id
LEFT JOIN product_category_name_translation t 
    ON p.product_category_name = t.product_category_name
GROUP BY t.product_category_name_english
ORDER BY revenue DESC
LIMIT 10;
```

### Delivery Performance KPI
```sql
SELECT 
    CASE 
        WHEN order_delivered_customer_date <= order_estimated_delivery_date 
        THEN 'On Time' ELSE 'Late' 
    END as status,
    COUNT(*) as orders,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2) as pct
FROM olist_orders_dataset
WHERE order_status = 'delivered'
GROUP BY 1;
```

**Result:** 93.2% on-time delivery rate

## Cost Analysis

| Service | Free Tier | Usage | Cost |
|---------|-----------|-------|------|
| S3 Storage | 5 GB | 26 MB | $0.00 |
| Lambda Invocations | 1M requests | 9 runs | $0.00 |
| Lambda Compute | 400K GB-sec | ~300 GB-sec | $0.00 |
| Glue Crawler | 1M objects | 9 tables | $0.00 |
| Athena Queries | 1 TB scanned | ~50 MB | $0.00 |

**Total Monthly Cost:** $0.00 (within Free Tier limits)

**Cost Optimization Techniques:**
- Parquet columnar format reduces Athena scan costs by 10x
- S3 lifecycle policy auto-deletes Athena results after 7 days
- Glue Crawler runs on-demand (not scheduled)
- Lambda uses pre-built layer (no deployment package bloat)

## Project Learnings

### Technical Challenges Solved
1. **Lambda Layer Strategy** - Used AWS Data Wrangler Layer to avoid 45MB pandas/pyarrow packaging complexity
2. **Schema Evolution** - Glue Crawler handles schema changes automatically on re-runs
3. **Parquet Optimization** - Snappy compression provided best speed/size tradeoff for this dataset
4. **Regional Limitations** - af-south-1 region required specific AWS SDK Pandas layer ARN

### What I'd Do Differently at Scale
- **Add Apache Airflow/Step Functions** for complex DAG orchestration
- **Implement Delta Lake/Iceberg** for ACID transactions and time travel
- **Enable S3 Event Notifications** to trigger Lambda automatically on file upload
- **Add dbt** for transformation logic testing and lineage tracking
- **Use AWS Glue ETL** (PySpark) for datasets >10 GB requiring distributed processing
- **Implement data quality framework** (Great Expectations/Deequ) with automated alerting

## Teardown
```bash
# Destroy all infrastructure (reversible within Terraform state retention)
cd terraform
terraform destroy  # Deletes all resources in ~60s

# Verify cleanup
aws s3 ls | grep olist  # Should return empty
aws glue get-databases --region af-south-1 | grep olist  # Should return empty
```

**Note:** S3 bucket versioning is enabled. Run `aws s3 rb s3://<bucket> --force` if terraform destroy fails.

## Project Structure

olist-serverless-data-pipeline/
├── terraform/                    # Infrastructure as Code
│   ├── main.tf                  # Resource definitions (S3, Lambda, Glue, Athena)
│   ├── variables.tf             # Configurable parameters
│   └── outputs.tf               # Bucket names, ARNs for scripts
├── lambda_functions/
│   └── csv_to_parquet/
│       ├── lambda_function.py   # Transformation logic (pandas → Parquet)
│       └── deploy_lambda_with_layer.sh
├── scripts/
│   ├── upload_data_to_s3.sh     # Bulk CSV upload
│   ├── transform_all_csvs.sh    # Invoke Lambda for all files
│   ├── run_athena_query.sh      # Query execution helper
│   └── analytics_queries.sql    # Business intelligence queries
├── data/
│   ├── raw/                     # Original CSVs (gitignored)
│   └── samples/                 # 100-row test files
└── docs/
    └── analytics_results/       # Query outputs for portfolio


## Skills Demonstrated

**Data Engineering:**
- ETL pipeline design (Extract, Transform, Load)
- Data lake architecture (raw → processed → analytics layers)
- Schema management and evolution
- Batch processing optimization
- Data quality validation

**AWS Cloud:**
- Serverless architecture patterns
- S3 lifecycle management and storage classes
- Lambda function development and optimization
- IAM security policies (least privilege)
- Glue Data Catalog and crawlers
- Athena query optimization

**DevOps/IaC:**
- Terraform resource provisioning
- CI/CD readiness (modular, parameterized code)
- Cost management and monitoring
- Infrastructure documentation

**Analytics:**
- SQL query optimization for columnar storage
- Business KPI definition and measurement
- Data modeling (star schema concepts)

---

## Contact

**LinkedIn:** www.linkedin.com/in/sekgweng-mampuru  
**GitHub:** s-thabang 


---

## License

MIT License - Free to use for educational/portfolio purposes

---

## Acknowledgments

- Dataset: [Olist - Brazilian E-Commerce Public Dataset](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce)
- Inspired by AWS Serverless Data Lake reference architecture
