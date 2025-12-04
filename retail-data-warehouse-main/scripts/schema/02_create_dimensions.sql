-- Date Dimension
CREATE TABLE analytics.dim_date (
    date_key SERIAL PRIMARY KEY,
    invoice_date DATE UNIQUE,
    day INTEGER,
    month INTEGER,
    year INTEGER,
    quarter INTEGER,
    day_of_week INTEGER,
    is_weekend BOOLEAN
);

-- Product Dimension
CREATE TABLE analytics.dim_product (
    stock_code VARCHAR(20) PRIMARY KEY,
    description TEXT
);

-- Customer Dimension
CREATE TABLE analytics.dim_customer (
    customer_id DECIMAL(10, 1) PRIMARY KEY,
    country VARCHAR(100)
);

-- Invoice Dimension
CREATE TABLE analytics.dim_invoice (
    invoice_number VARCHAR(20) PRIMARY KEY,
    customer_id DECIMAL(10, 1) REFERENCES analytics.dim_customer (customer_id),
    invoice_date DATE REFERENCES analytics.dim_date (invoice_date),
    country VARCHAR(100)
);