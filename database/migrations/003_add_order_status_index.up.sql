CREATE INDEX IX_sales_order_status_ordered_at
    ON dbo.sales_order(order_status, ordered_at_utc DESC)
    INCLUDE (customer_id);
