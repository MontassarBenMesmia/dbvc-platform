CREATE TABLE dbo.customer (
    customer_id int IDENTITY(1,1) NOT NULL CONSTRAINT PK_customer PRIMARY KEY,
    display_name nvarchar(120) NOT NULL,
    email nvarchar(254) NOT NULL CONSTRAINT UQ_customer_email UNIQUE,
    created_at_utc datetime2(3) NOT NULL CONSTRAINT DF_customer_created DEFAULT SYSUTCDATETIME()
);

CREATE TABLE dbo.product (
    product_id int IDENTITY(1,1) NOT NULL CONSTRAINT PK_product PRIMARY KEY,
    sku varchar(32) NOT NULL CONSTRAINT UQ_product_sku UNIQUE,
    product_name nvarchar(160) NOT NULL,
    unit_price decimal(12,2) NOT NULL CONSTRAINT CK_product_price CHECK (unit_price >= 0)
);

CREATE TABLE dbo.sales_order (
    order_id bigint IDENTITY(1,1) NOT NULL CONSTRAINT PK_sales_order PRIMARY KEY,
    customer_id int NOT NULL,
    order_status varchar(24) NOT NULL,
    ordered_at_utc datetime2(3) NOT NULL CONSTRAINT DF_order_created DEFAULT SYSUTCDATETIME(),
    CONSTRAINT FK_order_customer FOREIGN KEY (customer_id) REFERENCES dbo.customer(customer_id),
    CONSTRAINT CK_order_status CHECK (order_status IN ('draft', 'confirmed', 'fulfilled', 'cancelled'))
);

CREATE TABLE dbo.sales_order_item (
    order_id bigint NOT NULL,
    line_number smallint NOT NULL,
    product_id int NOT NULL,
    quantity int NOT NULL CONSTRAINT CK_order_item_quantity CHECK (quantity > 0),
    unit_price decimal(12,2) NOT NULL,
    CONSTRAINT PK_sales_order_item PRIMARY KEY (order_id, line_number),
    CONSTRAINT FK_order_item_order FOREIGN KEY (order_id) REFERENCES dbo.sales_order(order_id),
    CONSTRAINT FK_order_item_product FOREIGN KEY (product_id) REFERENCES dbo.product(product_id)
);
