-- Run against an existing application database using an account with schema permissions.
-- Creates missing tables only; existing tables and data are left unchanged.
SET XACT_ABORT ON;

BEGIN TRY
    BEGIN TRANSACTION;

    IF OBJECT_ID(N'dbo.products', N'U') IS NULL
    BEGIN
        CREATE TABLE dbo.products (
            id INT NOT NULL PRIMARY KEY,
            name NVARCHAR(255) NOT NULL,
            category NVARCHAR(100),
            price DECIMAL(10, 2),
            description NVARCHAR(MAX),
            is_organic BIT NOT NULL DEFAULT 0
        );
    END;

    IF OBJECT_ID(N'dbo.reviews', N'U') IS NULL
    BEGIN
        CREATE TABLE dbo.reviews (
            id INT IDENTITY(1,1) PRIMARY KEY,
            product_id INT REFERENCES dbo.products(id),
            rating FLOAT,
            reviewer_name NVARCHAR(255),
            review_text NVARCHAR(MAX)
        );
    END;

    IF OBJECT_ID(N'dbo.orders', N'U') IS NULL
    BEGIN
        CREATE TABLE dbo.orders (
            id INT IDENTITY(1,1) PRIMARY KEY,
            product_id INT NOT NULL REFERENCES dbo.products(id),
            product_name NVARCHAR(255) NOT NULL,
            price DECIMAL(10, 2) NOT NULL,
            ordered_at DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME()
        );
    END;

    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    IF XACT_STATE() <> 0
        ROLLBACK TRANSACTION;
    THROW;
END CATCH;
