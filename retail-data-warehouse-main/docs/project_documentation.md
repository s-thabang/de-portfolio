## Project Overview
Retail sales data warehouse processing 1M+ records from UK online retailer. Built with PostgreSQL, Python ETL, and Docker.

## Architecture Decisions

### Schema Design
- **Staging Layer**: Raw CSV replica for data preservation
- **Dimension Tables**: Customer, Product, Date, Invoice for star schema
- **Fact Table**: Line-level sales transactions with foreign keys
- **Analytics Views**: Pre-aggregated business metrics

### Data Quality Handling
- **Negative Quantities (22,950)**: Kept as valid business logic (product returns)
- **Negative Prices (5)**: Kept as valid business logic (refunds/credit notes)
- **Empty Strings**: Converted to NULL for proper database handling
- **No Data Filtering**: All original records preserved in staging

### ETL Strategy
- **Incremental Loading**: Scripts handle empty vs. existing tables
- **Error Resilience**: Continues on row-level failures with logging
- **Business Logic Preservation**: Returns analysis maintained for financial reporting

## Business Value Delivered

### Key Metrics Available
1. **Customer Lifetime Value** - Top customers by total spend
2. **Regional Performance** - Sales by country with ranking
3. **Product Analytics** - Best sellers and return rates
4. **Daily Trends** - Revenue and customer patterns over time
5. **Returns Analysis** - Product refund patterns and amounts

### Sample Insights
- United Kingdom is top-performing market
- Customer segmentation available for marketing
- Product return patterns identifiable for quality control
- Daily sales trends for inventory planning

## Technical Stack
- **Database**: PostgreSQL 13 (Docker)
- **ETL**: Python 3.12 with psycopg2
- **Analytics**: SQL Views + Jupyter Notebooks
- **Orchestration**: Docker Compose

# Design Decisions

## Phase 1: Infrastructure
- Used Docker for reproducible database environment
- Three-schema approach (staging, analytics, utils) for separation of concerns
- Virtual environment for Python dependency isolation

## Phase 2: Schema Design  
- Star schema for analytical query performance
- Separate invoice dimension for invoice-level analysis
- Date dimension for time intelligence capabilities

## Phase 3: ETL Development
- Preserved all raw data in staging layer
- Handled real-world data quality issues as business features
- Built incremental loading capability

## Phase 4: Testing & Validation
- Data quality tests treated negative values as business logic, not errors
- Row count validation ensured no data loss
- Relationship tests verified referential integrity

## Phase 5: Analytics
- Pre-aggregated views for common business questions
- Regional performance ranking for market analysis
- Returns analysis for product quality insights
