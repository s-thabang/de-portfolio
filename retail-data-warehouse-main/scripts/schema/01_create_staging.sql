CREATE TABLE staging.retail_sales_raw (
    invoice VARCHAR(20),
    stock_code VARCHAR(20),
    description TEXT,
    quantity INTEGER,
    invoice_date TIMESTAMP,
    price DECIMAL(10, 2),
    customer_id DECIMAL(10, 1),
    country VARCHAR(100)
);