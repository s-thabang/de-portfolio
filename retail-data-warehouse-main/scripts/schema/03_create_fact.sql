CREATE TABLE analytics.fact_sales (
    sales_id SERIAL PRIMARY KEY,
    invoice_number VARCHAR(20) REFERENCES analytics.dim_invoice (invoice_number),
    stock_code VARCHAR(20) REFERENCES analytics.dim_product (stock_code),
    customer_id DECIMAL(10, 1) REFERENCES analytics.dim_customer (customer_id),
    date_key INTEGER REFERENCES analytics.dim_date (date_key),
    quantity INTEGER,
    unit_price DECIMAL(10, 2),
    line_total DECIMAL(10, 2)
);