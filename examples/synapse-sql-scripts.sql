-- Synapse SQL Script Examples
-- Use these scripts in Synapse Analytics SQL Pool

-- ========================================
-- 1. Create External Data Source
-- ========================================

-- Create master key (required for credentials)
IF NOT EXISTS (SELECT * FROM sys.symmetric_keys WHERE name = '##MS_DatabaseMasterKey##')
BEGIN
    CREATE MASTER KEY ENCRYPTION BY PASSWORD = 'YourStrongPassword123!';
END
GO

-- Create database scoped credential using Managed Identity
CREATE DATABASE SCOPED CREDENTIAL DataLakeCredential
WITH IDENTITY = 'Managed Identity';
GO

-- Create external data source pointing to Data Lake
CREATE EXTERNAL DATA SOURCE DataLakeStorage
WITH (
    TYPE = HADOOP,
    LOCATION = 'abfss://datawarehouse@<your-storage-account>.dfs.core.windows.net',
    CREDENTIAL = DataLakeCredential
);
GO

-- ========================================
-- 2. Create External File Format
-- ========================================

-- For Parquet files
CREATE EXTERNAL FILE FORMAT ParquetFormat
WITH (
    FORMAT_TYPE = PARQUET,
    DATA_COMPRESSION = 'org.apache.hadoop.io.compress.SnappyCodec'
);
GO

-- For CSV files (if needed)
CREATE EXTERNAL FILE FORMAT CSVFormat
WITH (
    FORMAT_TYPE = DELIMITEDTEXT,
    FORMAT_OPTIONS (
        FIELD_TERMINATOR = ',',
        STRING_DELIMITER = '"',
        FIRST_ROW = 2,
        USE_TYPE_DEFAULT = TRUE
    ),
    DATA_COMPRESSION = 'org.apache.hadoop.io.compress.GzipCodec'
);
GO

-- ========================================
-- 3. Create External Tables
-- ========================================

-- Create schema for external tables
CREATE SCHEMA external;
GO

-- Create external table for transformed data
CREATE EXTERNAL TABLE external.TransformedData
(
    id INT,
    timestamp DATETIME2,
    value FLOAT,
    value_normalized FLOAT,
    date DATE,
    year INT,
    month INT,
    day INT,
    processed_timestamp DATETIME2,
    source_container VARCHAR(50),
    processing_date DATE
)
WITH (
    LOCATION = '/transformed_data',
    DATA_SOURCE = DataLakeStorage,
    FILE_FORMAT = ParquetFormat
);
GO

-- ========================================
-- 4. Create Materialized Views
-- ========================================

-- Create schema for curated data
CREATE SCHEMA curated;
GO

-- Create materialized view for daily aggregates
CREATE VIEW curated.DailyAggregates
AS
SELECT
    date,
    COUNT(*) as record_count,
    AVG(value) as avg_value,
    MIN(value) as min_value,
    MAX(value) as max_value,
    SUM(value) as total_value,
    STDEV(value) as stddev_value
FROM external.TransformedData
GROUP BY date;
GO

-- Create view for monthly aggregates
CREATE VIEW curated.MonthlyAggregates
AS
SELECT
    year,
    month,
    COUNT(*) as record_count,
    AVG(value) as avg_value,
    SUM(value) as total_value
FROM external.TransformedData
GROUP BY year, month;
GO

-- ========================================
-- 5. Create Stored Procedures
-- ========================================

-- Procedure to refresh aggregates
CREATE PROCEDURE curated.sp_RefreshAggregates
AS
BEGIN
    -- This is a placeholder for your refresh logic
    -- In production, you might want to:
    -- 1. Truncate staging tables
    -- 2. Load new data
    -- 3. Update dimension tables
    -- 4. Update fact tables
    
    PRINT 'Aggregates refreshed successfully';
END;
GO

-- ========================================
-- 6. Sample Queries
-- ========================================

-- Query 1: Get daily statistics
SELECT
    date,
    record_count,
    avg_value,
    min_value,
    max_value
FROM curated.DailyAggregates
WHERE date >= DATEADD(day, -30, GETDATE())
ORDER BY date DESC;

-- Query 2: Get top records by value
SELECT TOP 100
    id,
    timestamp,
    value,
    date
FROM external.TransformedData
ORDER BY value DESC;

-- Query 3: Monthly trend analysis
SELECT
    year,
    month,
    record_count,
    avg_value,
    LAG(avg_value) OVER (ORDER BY year, month) as prev_month_avg,
    avg_value - LAG(avg_value) OVER (ORDER BY year, month) as change
FROM curated.MonthlyAggregates
ORDER BY year DESC, month DESC;

-- ========================================
-- 7. Performance Optimization
-- ========================================

-- Create statistics for better query performance
CREATE STATISTICS stat_date ON external.TransformedData(date);
CREATE STATISTICS stat_value ON external.TransformedData(value);
CREATE STATISTICS stat_year_month ON external.TransformedData(year, month);

-- ========================================
-- 8. Monitoring Queries
-- ========================================

-- Check table sizes and row counts
SELECT
    s.name as schema_name,
    t.name as table_name,
    p.rows as row_count,
    SUM(a.total_pages) * 8 / 1024 as total_space_mb
FROM sys.tables t
INNER JOIN sys.schemas s ON t.schema_id = s.schema_id
INNER JOIN sys.partitions p ON t.object_id = p.object_id
INNER JOIN sys.allocation_units a ON p.partition_id = a.container_id
WHERE p.index_id IN (0,1)
GROUP BY s.name, t.name, p.rows
ORDER BY row_count DESC;

-- Check recent query performance
SELECT
    TOP 10
    r.request_id,
    r.status,
    r.command,
    r.total_elapsed_time / 1000.0 as elapsed_time_seconds,
    r.start_time,
    r.end_time
FROM sys.dm_pdw_exec_requests r
WHERE r.session_id <> SESSION_ID()
ORDER BY r.start_time DESC;
