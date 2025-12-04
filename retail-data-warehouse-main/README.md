# Retail Data Warehouse ETL Pipeline

A complete data engineering project that processes 1,067,371 retail sales records through a full ETL pipeline.

## Project Overview
- **Data Source**: Online Retail II dataset (UCI Machine Learning Repository)
- **Records Processed**: 1,067,371 sales transactions
- **Tech Stack**: PostgreSQL, Python, Docker, CSV processing
- **Architecture**: Staging → Star Schema → Analytics Views

## Getting Started

### Prerequisites
- Docker and Docker Compose
- Python 3.12+

### Quick Setup
```bash
# 1. Start PostgreSQL
docker-compose up -d

# 2. Setup Python environment
python -m venv venv
source venv/bin/activate
pip install psycopg2-binary python-dotenv

# 3. Load data
python tests/test_staging_data.py

# 4. Verify
python tests/test_connection.py
python tests/test_data_quality.py
```

## What We Built

### Phase 1: Infrastructure
- PostgreSQL in Docker container
- Three-schema database: staging, analytics, utils
- Virtual environment setup
- Database connection testing

### Phase 2: Schema Design
- Staging table: `staging.retail_sales_raw` (exact CSV replica)
- Dimension tables: `dim_customer`, `dim_product`, `dim_date`, `dim_invoice`
- Fact table: `fact_sales` with foreign keys
- All tables created in PostgreSQL

#### Why This Design?
- **Business Alignment**: Each dimension maps to key business entities
- **Query Performance**: Star schema optimized for analytical queries
- **Flexibility**: Dimensions can be enriched without affecting fact table
- **Scalability**: New attributes can be added to dimensions as needed

### Phase 3: ETL Development
- CSV loader with empty string handling
- Data quality checks
- Business-aware validation (negative values as returns/refunds)
- Error handling for malformed rows

### Phase 4: Testing & Validation
- Staging data loaded: 1,067,371 rows verified
- Data quality analyzed: Found 22,950 returns (negative quantities)
- Business logic validated: Negative values = valid transactions
- All tests passing with business context

### Phase 5: Analytics & Documentation
- 6 Analytics views created:
  1. `vw_daily_revenue` - Daily sales trends
  2. `vw_customer_summary` - Customer analytics
  3. `vw_product_performance` - Product metrics
  4. `vw_returns_analysis` - Return patterns
  5. `vw_regional_performance` - Geographic analysis
  6. `vw_monthly_regional_sales` - Time-series by region
- Complete project documentation
- Business insights ready for analysis

## Project Structure
```
data_warehouse_project/
├── data/                    # Data directories
├── src/                    # ETL source code
├── scripts/                # SQL scripts
├── tests/                  # Test suite
├── docs/                   # Documentation
├── docker-compose.yml      # Database setup
└── requirements.txt        # Python dependencies
```

## Business Insights Discovered
- **Total Records**: 1,067,371 sales transactions
- **Returns Identified**: 22,950 (negative quantities) - normal business operations
- **Refunds**: 5 (negative prices) - valid credit notes
- **Primary Market**: United Kingdom (top performing region)

## Key Features Implemented

### 1. **Real-World Data Handling**
```python
# Empty strings converted to NULL
processed_row = [None if value == '' else value for value in row]

# Business-aware validation
if quantity < 0:  # Not an error - it's a return
    log_return_transaction(invoice, stock_code, quantity)
```

### 2. **Complete ETL Pipeline**
- Raw CSV → Staging table → Dimensions → Facts → Analytics
- Error handling continues processing on row failures
- All original data preserved in staging layer

### 3. **Production-Ready Database**
```sql
-- Example analytics query
SELECT country, total_revenue, performance_rank
FROM analytics.vw_regional_performance
ORDER BY total_revenue DESC;
```

## Testing Commands
```bash
# Test database connection
python tests/test_connection.py

# Test data quality (business-aware)
python tests/test_data_quality.py

# Load and verify staging data
python tests/test_staging_data.py
```

## Documentation
- `docs/PROJECT_DOCUMENTATION.md` - Complete project documentation
- `docs/DESIGN_DECISIONS.md` - Architecture and design choices

## What This Project Demonstrates
- **End-to-end ETL pipeline** from raw CSV to analytics
- **Production data challenges** handling real-world anomalies
- **Business intelligence** through SQL views
- **Data engineering best practices** with staging layers
- **Testing with business context** understanding real data patterns

## Daily Workflow
```bash
# 1. Start database
docker-compose up -d

# 2. Activate environment
source venv/bin/activate

# 3. Run analysis
docker exec dw_postgres psql -U etl_user -d data_warehouse -c "SELECT * FROM analytics.vw_daily_revenue LIMIT 10;"

# 4. Stop when done
docker-compose down
```
**Project Status**: Complete  
**Data Processed**: 1,067,371 records  
**Business Insights**: Ready for analysis  
**Code Quality**: Tested and documented  
