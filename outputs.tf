# Output values for Azure Data Analytics Platform

output "resource_group_name" {
  description = "Name of the resource group"
  value       = azurerm_resource_group.main.name
}

output "resource_group_location" {
  description = "Location of the resource group"
  value       = azurerm_resource_group.main.location
}

# Data Lake Storage Outputs
output "datalake_storage_account_name" {
  description = "Name of the Data Lake Storage Gen2 account"
  value       = azurerm_storage_account.datalake.name
}

output "datalake_primary_dfs_endpoint" {
  description = "Primary DFS endpoint for Data Lake Storage"
  value       = azurerm_storage_account.datalake.primary_dfs_endpoint
}

output "datalake_containers" {
  description = "List of Data Lake containers"
  value = {
    landing      = azurerm_storage_data_lake_gen2_filesystem.landing.name
    malformed    = azurerm_storage_data_lake_gen2_filesystem.malformed.name
    interim      = azurerm_storage_data_lake_gen2_filesystem.interim.name
    datawarehouse = azurerm_storage_data_lake_gen2_filesystem.datawarehouse.name
  }
}

# Data Factory Outputs
output "data_factory_name" {
  description = "Name of the Azure Data Factory"
  value       = azurerm_data_factory.main.name
}

output "data_factory_id" {
  description = "ID of the Azure Data Factory"
  value       = azurerm_data_factory.main.id
}

output "data_factory_identity_principal_id" {
  description = "Principal ID of Data Factory managed identity"
  value       = azurerm_data_factory.main.identity[0].principal_id
}

# Databricks Outputs
output "databricks_workspace_name" {
  description = "Name of the Azure Databricks workspace"
  value       = azurerm_databricks_workspace.main.name
}

output "databricks_workspace_url" {
  description = "URL of the Azure Databricks workspace"
  value       = azurerm_databricks_workspace.main.workspace_url
}

output "databricks_workspace_id" {
  description = "ID of the Azure Databricks workspace"
  value       = azurerm_databricks_workspace.main.workspace_id
}

# Synapse Analytics Outputs
output "synapse_workspace_name" {
  description = "Name of the Azure Synapse workspace"
  value       = azurerm_synapse_workspace.main.name
}

output "synapse_workspace_endpoint" {
  description = "Endpoint URL for Azure Synapse workspace"
  value       = azurerm_synapse_workspace.main.connectivity_endpoints
}

output "synapse_sql_pool_name" {
  description = "Name of the Synapse SQL Pool"
  value       = azurerm_synapse_sql_pool.main.name
}

output "synapse_sql_admin_username" {
  description = "Synapse SQL administrator username"
  value       = var.synapse_sql_admin_username
  sensitive   = true
}

# Key Vault Outputs
output "key_vault_name" {
  description = "Name of the Azure Key Vault"
  value       = azurerm_key_vault.main.name
}

output "key_vault_uri" {
  description = "URI of the Azure Key Vault"
  value       = azurerm_key_vault.main.vault_uri
}

# Summary Output
output "architecture_summary" {
  description = "Summary of the deployed architecture"
  value = {
    resource_group     = azurerm_resource_group.main.name
    data_lake         = azurerm_storage_account.datalake.name
    data_factory      = azurerm_data_factory.main.name
    databricks        = azurerm_databricks_workspace.main.name
    synapse_workspace = azurerm_synapse_workspace.main.name
    synapse_sql_pool  = azurerm_synapse_sql_pool.main.name
    key_vault         = azurerm_key_vault.main.name
  }
}

output "next_steps" {
  description = "Next steps after deployment"
  value = <<-EOT
    
    ========================================
    Azure Data Analytics Platform Deployed!
    ========================================
    
    Data Lake Storage: ${azurerm_storage_account.datalake.name}
    - Landing Container: landing
    - Malformed Container: malformed
    - Interim Container: interim
    - Data Warehouse Container: datawarehouse
    
    Data Factory: ${azurerm_data_factory.main.name}
    - Portal: https://adf.azure.com
    
    Databricks Workspace: ${azurerm_databricks_workspace.main.name}
    - URL: https://${azurerm_databricks_workspace.main.workspace_url}
    
    Synapse Analytics: ${azurerm_synapse_workspace.main.name}
    - Synapse Studio: https://web.azuresynapse.net
    - SQL Pool: ${azurerm_synapse_sql_pool.main.name}
    
    Key Vault: ${azurerm_key_vault.main.name}
    
    Next Steps:
    1. Access Databricks workspace to create notebooks
    2. Configure Data Factory pipelines to ingest data
    3. Create Databricks jobs for data transformation
    4. Set up Synapse SQL queries and views
    5. Configure monitoring and alerts
    
    ========================================
  EOT
}
