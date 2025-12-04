-- Create staging schema for raw data
CREATE SCHEMA IF NOT EXISTS staging;

-- Create analytics schema for processed data
CREATE SCHEMA IF NOT EXISTS analytics;

-- Create utility schema for ETL processes
CREATE SCHEMA IF NOT EXISTS utils;

-- Grant permissions to our ETL user
GRANT ALL PRIVILEGES ON SCHEMA staging TO etl_user;

GRANT ALL PRIVILEGES ON SCHEMA analytics TO etl_user;

GRANT ALL PRIVILEGES ON SCHEMA utils TO etl_user;