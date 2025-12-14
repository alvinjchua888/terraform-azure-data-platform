# Databricks notebook source
# MAGIC %md
# MAGIC # Data Transformation Pipeline
# MAGIC 
# MAGIC This notebook reads data from the Landing container, performs transformations, and writes to the Interim container.

# COMMAND ----------

# MAGIC %md
# MAGIC ## 1. Setup and Configuration

# COMMAND ----------

from pyspark.sql import SparkSession
from pyspark.sql.functions import *
from pyspark.sql.types import *
import logging

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# COMMAND ----------

# MAGIC %md
# MAGIC ## 2. Read Data from Landing Container

# COMMAND ----------

# Define input and output paths
storage_account = "<your-datalake-storage-account>"
landing_container = "landing"
interim_container = "interim"
malformed_container = "malformed"

# Read data from landing
try:
    df_raw = spark.read \
        .format("parquet") \
        .option("header", "true") \
        .option("inferSchema", "true") \
        .load(f"abfss://{landing_container}@{storage_account}.dfs.core.windows.net/")
    
    logger.info(f"Successfully read {df_raw.count()} records from landing")
    df_raw.printSchema()
except Exception as e:
    logger.error(f"Error reading from landing: {str(e)}")
    raise

# COMMAND ----------

# MAGIC %md
# MAGIC ## 3. Data Quality Checks

# COMMAND ----------

# Define data quality rules
def validate_data(df):
    """
    Validate data quality and separate good from bad records
    """
    # Add validation flag column
    df_validated = df.withColumn(
        "is_valid",
        when(
            (col("id").isNotNull()) &
            (col("timestamp").isNotNull()) &
            (col("value").isNotNull()) &
            (col("value") >= 0),
            lit(True)
        ).otherwise(lit(False))
    )
    
    # Separate valid and invalid records
    df_valid = df_validated.filter(col("is_valid") == True).drop("is_valid")
    df_invalid = df_validated.filter(col("is_valid") == False).drop("is_valid")
    
    return df_valid, df_invalid

# Apply validation
df_valid, df_malformed = validate_data(df_raw)

logger.info(f"Valid records: {df_valid.count()}")
logger.info(f"Malformed records: {df_malformed.count()}")

# COMMAND ----------

# MAGIC %md
# MAGIC ## 4. Data Transformation

# COMMAND ----------

# Transform valid data
df_transformed = df_valid \
    .withColumn("processed_timestamp", current_timestamp()) \
    .withColumn("date", to_date(col("timestamp"))) \
    .withColumn("year", year(col("timestamp"))) \
    .withColumn("month", month(col("timestamp"))) \
    .withColumn("day", dayofmonth(col("timestamp"))) \
    .withColumn("value_normalized", col("value") / 100.0) \
    .dropDuplicates(["id", "timestamp"])

# Add data lineage information
df_transformed = df_transformed \
    .withColumn("source_container", lit("landing")) \
    .withColumn("processing_date", current_date())

logger.info(f"Transformed {df_transformed.count()} records")

# COMMAND ----------

# MAGIC %md
# MAGIC ## 5. Write to Interim Container

# COMMAND ----------

# Write transformed data to interim (partitioned by date)
try:
    df_transformed.write \
        .mode("append") \
        .partitionBy("year", "month", "day") \
        .parquet(f"abfss://{interim_container}@{storage_account}.dfs.core.windows.net/transformed_data")
    
    logger.info("Successfully wrote data to interim container")
except Exception as e:
    logger.error(f"Error writing to interim: {str(e)}")
    raise

# COMMAND ----------

# MAGIC %md
# MAGIC ## 6. Write Malformed Data

# COMMAND ----------

# Write malformed records to malformed container for investigation
if df_malformed.count() > 0:
    try:
        df_malformed.withColumn("error_timestamp", current_timestamp()) \
            .write \
            .mode("append") \
            .parquet(f"abfss://{malformed_container}@{storage_account}.dfs.core.windows.net/errors")
        
        logger.info(f"Wrote {df_malformed.count()} malformed records")
    except Exception as e:
        logger.error(f"Error writing malformed data: {str(e)}")

# COMMAND ----------

# MAGIC %md
# MAGIC ## 7. Log Summary Statistics

# COMMAND ----------

# Create summary
summary = {
    "total_records": df_raw.count(),
    "valid_records": df_valid.count(),
    "malformed_records": df_malformed.count(),
    "processed_timestamp": str(current_timestamp())
}

print("Pipeline Execution Summary:")
for key, value in summary.items():
    print(f"  {key}: {value}")

# COMMAND ----------

# Return success status
dbutils.notebook.exit({"status": "success", "summary": summary})
