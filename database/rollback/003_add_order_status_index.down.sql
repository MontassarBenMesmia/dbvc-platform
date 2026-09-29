IF EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_sales_order_status_ordered_at' AND object_id = OBJECT_ID('dbo.sales_order'))
    DROP INDEX IX_sales_order_status_ordered_at ON dbo.sales_order;
