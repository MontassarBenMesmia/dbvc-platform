INSERT INTO dbo.customer(display_name, email) VALUES
    (N'Demo Retail', N'ops@demo-retail.example'),
    (N'Northwind Lab', N'engineering@northwind-lab.example');

INSERT INTO dbo.product(sku, product_name, unit_price) VALUES
    ('DBVC-START', N'Database Delivery Starter', 49.00),
    ('DBVC-TEAM', N'Database Delivery Team', 129.00);
