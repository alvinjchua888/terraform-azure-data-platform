# Main Terraform configuration for Azure Data Analytics Platform

terraform {
  required_version = ">= 1.0"
  
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 2.0"
    }
  }
}

provider "azurerm" {
  features {
    key_vault {
      purge_soft_delete_on_destroy = true
    }
  }
}

# Random string for unique resource names
resource "random_string" "suffix" {
  length  = 6
  special = false
  upper   = false
}

# Resource Group
resource "azurerm_resource_group" "main" {
  name     = var.resource_group_name
  location = var.location
  
  tags = var.tags
}

# ==========================================
# Data Lake Storage Gen2 with Containers
# ==========================================

resource "azurerm_storage_account" "datalake" {
  name                     = "${var.prefix}adls${random_string.suffix.result}"
  resource_group_name      = azurerm_resource_group.main.name
  location                 = azurerm_resource_group.main.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  account_kind             = "StorageV2"
  is_hns_enabled           = true  # Hierarchical namespace for Data Lake Gen2
  
  tags = var.tags
}

# Data Lake Containers
resource "azurerm_storage_data_lake_gen2_filesystem" "landing" {
  name               = "landing"
  storage_account_id = azurerm_storage_account.datalake.id
}

resource "azurerm_storage_data_lake_gen2_filesystem" "malformed" {
  name               = "malformed"
  storage_account_id = azurerm_storage_account.datalake.id
}

resource "azurerm_storage_data_lake_gen2_filesystem" "interim" {
  name               = "interim"
  storage_account_id = azurerm_storage_account.datalake.id
}

resource "azurerm_storage_data_lake_gen2_filesystem" "datawarehouse" {
  name               = "datawarehouse"
  storage_account_id = azurerm_storage_account.datalake.id
}

# ==========================================
# Azure Data Factory
# ==========================================

resource "azurerm_data_factory" "main" {
  name                = "${var.prefix}-adf-${random_string.suffix.result}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  
  identity {
    type = "SystemAssigned"
  }
  
  tags = var.tags
}

# Grant Data Factory access to Data Lake Storage
resource "azurerm_role_assignment" "adf_to_datalake" {
  scope                = azurerm_storage_account.datalake.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azurerm_data_factory.main.identity[0].principal_id
}

# Data Factory Linked Service to Data Lake
resource "azurerm_data_factory_linked_service_data_lake_storage_gen2" "datalake" {
  name                = "LinkedService_DataLake"
  data_factory_id     = azurerm_data_factory.main.id
  url                 = azurerm_storage_account.datalake.primary_dfs_endpoint
  use_managed_identity = true
}

# ==========================================
# Azure Databricks Workspace
# ==========================================

resource "azurerm_databricks_workspace" "main" {
  name                = "${var.prefix}-databricks-${random_string.suffix.result}"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  sku                 = var.databricks_sku
  
  tags = var.tags
}

# Grant Databricks access to Data Lake Storage
resource "azurerm_role_assignment" "databricks_to_datalake" {
  scope                = azurerm_storage_account.datalake.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azurerm_databricks_workspace.main.storage_account_identity[0].principal_id
}

# ==========================================
# Azure Synapse Analytics Workspace
# ==========================================

# Synapse requires a separate storage account for workspace
resource "azurerm_storage_account" "synapse" {
  name                     = "${var.prefix}synapse${random_string.suffix.result}"
  resource_group_name      = azurerm_resource_group.main.name
  location                 = azurerm_resource_group.main.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  account_kind             = "StorageV2"
  is_hns_enabled           = true
  
  tags = var.tags
}

resource "azurerm_storage_data_lake_gen2_filesystem" "synapse" {
  name               = "synapse"
  storage_account_id = azurerm_storage_account.synapse.id
}

# Synapse Workspace
resource "azurerm_synapse_workspace" "main" {
  name                                 = "${var.prefix}-synapse-${random_string.suffix.result}"
  resource_group_name                  = azurerm_resource_group.main.name
  location                             = azurerm_resource_group.main.location
  storage_data_lake_gen2_filesystem_id = azurerm_storage_data_lake_gen2_filesystem.synapse.id
  sql_administrator_login              = var.synapse_sql_admin_username
  sql_administrator_login_password     = var.synapse_sql_admin_password
  
  identity {
    type = "SystemAssigned"
  }
  
  tags = var.tags
}

# Synapse SQL Pool (Dedicated SQL Pool / Data Warehouse)
resource "azurerm_synapse_sql_pool" "main" {
  name                 = "${var.prefix}sqlpool"
  synapse_workspace_id = azurerm_synapse_workspace.main.id
  sku_name             = var.synapse_sql_pool_sku
  create_mode          = "Default"
  
  tags = var.tags
}

# Grant Synapse access to Data Lake Storage
resource "azurerm_role_assignment" "synapse_to_datalake" {
  scope                = azurerm_storage_account.datalake.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azurerm_synapse_workspace.main.identity[0].principal_id
}

# Synapse Firewall Rule (Allow Azure services)
resource "azurerm_synapse_firewall_rule" "allow_azure_services" {
  name                 = "AllowAllWindowsAzureIps"
  synapse_workspace_id = azurerm_synapse_workspace.main.id
  start_ip_address     = "0.0.0.0"
  end_ip_address       = "0.0.0.0"
}

# Synapse Firewall Rule (Allow your IP - optional)
resource "azurerm_synapse_firewall_rule" "allow_all" {
  name                 = "AllowAll"
  synapse_workspace_id = azurerm_synapse_workspace.main.id
  start_ip_address     = "0.0.0.0"
  end_ip_address       = "255.255.255.255"
}

# ==========================================
# Azure Key Vault (for secrets management)
# ==========================================

data "azurerm_client_config" "current" {}

resource "azurerm_key_vault" "main" {
  name                       = "${var.prefix}-kv-${random_string.suffix.result}"
  location                   = azurerm_resource_group.main.location
  resource_group_name        = azurerm_resource_group.main.name
  tenant_id                  = data.azurerm_client_config.current.tenant_id
  sku_name                   = "standard"
  soft_delete_retention_days = 7
  purge_protection_enabled   = false
  
  tags = var.tags
}

# Key Vault Access Policy for current user
resource "azurerm_key_vault_access_policy" "current_user" {
  key_vault_id = azurerm_key_vault.main.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = data.azurerm_client_config.current.object_id
  
  secret_permissions = [
    "Get", "List", "Set", "Delete", "Purge", "Recover"
  ]
}

# Key Vault Access Policy for Data Factory
resource "azurerm_key_vault_access_policy" "adf" {
  key_vault_id = azurerm_key_vault.main.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = azurerm_data_factory.main.identity[0].principal_id
  
  secret_permissions = [
    "Get", "List"
  ]
}

# Key Vault Access Policy for Synapse
resource "azurerm_key_vault_access_policy" "synapse" {
  key_vault_id = azurerm_key_vault.main.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = azurerm_synapse_workspace.main.identity[0].principal_id
  
  secret_permissions = [
    "Get", "List"
  ]
}

# Store Data Lake connection string in Key Vault
resource "azurerm_key_vault_secret" "datalake_connection_string" {
  name         = "datalake-connection-string"
  value        = azurerm_storage_account.datalake.primary_connection_string
  key_vault_id = azurerm_key_vault.main.id
  
  depends_on = [azurerm_key_vault_access_policy.current_user]
}
