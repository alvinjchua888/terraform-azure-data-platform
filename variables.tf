# Variable definitions for Azure Data Analytics Platform

variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
  default     = "rg-data-analytics-platform"
}

variable "location" {
  description = "Azure region for resources"
  type        = string
  default     = "East US"
}

variable "prefix" {
  description = "Prefix for resource names (keep it short, 3-6 characters)"
  type        = string
  default     = "dap"
}

variable "databricks_sku" {
  description = "SKU for Azure Databricks workspace"
  type        = string
  default     = "standard"
  validation {
    condition     = contains(["standard", "premium", "trial"], var.databricks_sku)
    error_message = "Databricks SKU must be standard, premium, or trial."
  }
}

variable "synapse_sql_admin_username" {
  description = "Administrator username for Synapse SQL"
  type        = string
  default     = "sqladmin"
}

variable "synapse_sql_admin_password" {
  description = "Administrator password for Synapse SQL (must meet complexity requirements)"
  type        = string
  sensitive   = true
  default     = "P@ssw0rd123!"
}

variable "synapse_sql_pool_sku" {
  description = "SKU for Synapse SQL Pool (DW100c to DW30000c)"
  type        = string
  default     = "DW100c"
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default = {
    Environment = "Development"
    ManagedBy   = "Terraform"
    Project     = "Data-Analytics-Platform"
    Architecture = "Data-Lake-Databricks-Synapse"
  }
}
