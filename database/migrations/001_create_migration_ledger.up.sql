IF OBJECT_ID('dbo.dbvc_schema_version', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.dbvc_schema_version (
        version char(3) NOT NULL CONSTRAINT PK_dbvc_schema_version PRIMARY KEY,
        name nvarchar(160) NOT NULL,
        checksum_sha256 char(64) NOT NULL,
        applied_at_utc datetime2(3) NOT NULL
    );
END;
