-- Materialized view
CREATE MATERIALIZED VIEW sales_accumulated_monthly_mv AS
    SELECT
        EXTRACT(YEAR FROM o.order_date) AS year,
        EXTRACT(MONTH FROM o.order_date) AS month,
        SUM(od.unit_price * od.quantity * (1 - od.discount)) AS monthly_sales,
        ROUND(
            CAST(
                SUM(
                    (od.unit_price * od.quantity)  * (1.0 - od.discount)
                ) OVER (
                    PARTITION BY EXTRACT(YEAR FROM o.order_date)
                    ORDER BY EXTRACT(MONTH FROM o.order_date)
                )
                AS numeric
            ),
            2
        ) AS sales_ytd
    FROM
        orders o
        INNER JOIN order_details od ON od.order_id = o.order_id
    GROUP BY
        EXTRACT(YEAR FROM o.order_date),
        EXTRACT(MONTH FROM o.order_date)
    ORDER BY
        1, 2;

-- Triggers
CREATE OR REPLACE FUNCTION refresh_sales_accumulated_monthly_mv() RETURNS TRIGGER AS $$
    BEGIN
        REFRESH MATERIALIZED VIEW sales_accumulated_monthly_mv;
        RETURN NULL;
    END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER trg_refresh_sales_accumulated_monthly_mv_order_details
    AFTER INSERT OR UPDATE OR DELETE ON order_details
    FOR EACH STATEMENT
    EXECUTE PROCEDURE refresh_sales_accumulated_monthly_mv();

CREATE OR REPLACE TRIGGER trg_refresh_sales_accumulated_monthly_mv_orderS
    AFTER INSERT OR UPDATE OR DELETE ON order
    FOR EACH STATEMENT
    EXECUTE PROCEDURE refresh_sales_accumulated_monthly_mv();

-- Stored Procedures