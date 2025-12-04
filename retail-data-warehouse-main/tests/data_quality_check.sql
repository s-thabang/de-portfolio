SELECT
    SUM(
        CASE
            WHEN price < 0 THEN 1
            ELSE 0
        END
    ) as negative_prices,
    SUM(
        CASE
            WHEN quantity < 0 THEN 1
            ELSE 0
        END
    ) as negative_quantities
FROM staging.retail_sales_raw;