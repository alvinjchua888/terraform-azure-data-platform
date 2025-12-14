# Azure Data Analytics Platform with Terraform

This repository contains Terraform configuration files to provision a complete Azure Data Analytics Platform with Data Lake, Data Factory, Databricks, and Synapse Analytics.

## Architecture

📊 **See detailed architecture diagram**: [ARCHITECTURE.md](ARCHITECTURE.md)

This Terraform configuration creates a modern data analytics platform with the following Azure resources:

### Core Components

1. **Azure Data Lake Storage Gen2**
   - Landing container: Raw data ingestion
   - Malformed container: Invalid/error data
   - Interim container: Transformed data in progress
   - Data Warehouse container: Final curated data

2. **Azure Data Factory**
   - Data orchestration and ETL pipelines
   - Managed identity for secure access
   - Linked service to Data Lake Storage

3. **Azure Databricks**
   - Workspace for data transformation and cleansing
   - Apache Spark processing engine
   - Access to Data Lake Storage

4. **Azure Synapse Analytics**
   - Dedicated SQL Pool (Data Warehouse)
   - SQL-based analytics and queries
   - Integration with Data Lake

5. **Azure Key Vault**
   - Secure storage for connection strings and secrets
   - Access policies for all services

### Data Flow

```
Source Data → Data Factory → Data Lake (Landing) 
                                    ↓
                              Databricks (Transform/Cleanse)
                                    ↓
                              Data Lake (Interim)
                                    ↓
                              Data Lake (Data Warehouse)
                                    ↓
                              Synapse Analytics (SQL Pool)
```

## Prerequisites

Before you begin, ensure you have:

1. **Azure CLI** installed and configured
   ```bash
   az login
   az account show
   az account list --output table
   ```

2. **Terraform** installed (version >= 1.0)
   ```bash
   terraform version
   ```

3. **Azure Subscription** with appropriate permissions
   - Contributor or Owner role on the subscription
   - Ability to create service principals and managed identities

## Usage

### 1. Clone or Download This Repository

```bash
git clone <your-repo-url>
cd terraform-azure-githubcopilot
```

### 2. Configure Variables

Copy the example variables file and customize it:

```bash
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars` to customize values:

```hcl
resource_group_name        = "rg-data-analytics-prod"
location                   = "East US"
prefix                     = "prod"
databricks_sku            = "standard"
synapse_sql_admin_username = "sqladmin"
synapse_sql_admin_password = "YourSecurePassword123!"
synapse_sql_pool_sku      = "DW100c"
```

**Important**: The `synapse_sql_admin_password` must meet Azure's complexity requirements:
- At least 8 characters
- Contains uppercase and lowercase letters
- Contains numbers
- Contains special characters

### 3. Initialize Terraform

Initialize the Terraform working directory and download providers:

```bash
terraform init
```

### 4. Review the Plan

Preview the changes Terraform will make:

```bash
terraform plan
```

This will show you all resources that will be created.

### 5. Apply the Configuration

Create the infrastructure:

```bash
terraform apply
```

Type `yes` when prompted to confirm. The deployment will take approximately 10-15 minutes.

### 6. View Outputs

After successful deployment, view the important details:

```bash
terraform output
```

You'll see:
- Data Lake Storage account name and endpoints
- Data Factory name
- Databricks workspace URL
- Synapse workspace endpoint
- Key Vault name

## Configuration Files

- `main.tf`: Main Terraform configuration with all Azure resources
- `variables.tf`: Input variable declarations with defaults
- `outputs.tf`: Output value definitions for easy access
- `terraform.tfvars.example`: Example configuration template
- `.gitignore`: Git ignore patterns for sensitive files

## Post-Deployment Steps

### 1. Access Azure Data Factory

```bash
# Get the Data Factory name
terraform output data_factory_name

# Open in browser
# Navigate to: https://adf.azure.com
```

Create your data pipelines:
- Source: Connect to your data sources (SQL, files, APIs)
- Copy Data activity: Move data to Landing container
- Data Flow: Transform and validate data

### 2. Access Databricks Workspace

```bash
# Get the Databricks URL
terraform output databricks_workspace_url
```

Set up Databricks:
- Create a cluster (runtime 11.3 LTS or later recommended)
- Mount the Data Lake Storage
- Create notebooks for data transformation
- Schedule jobs for automated processing

Example notebook to mount Data Lake:

```python
# Mount Data Lake Storage
storage_account = "<your-storage-account>"
container = "landing"
mount_point = "/mnt/landing"

configs = {
  "fs.azure.account.auth.type": "OAuth",
  "fs.azure.account.oauth.provider.type": "org.apache.hadoop.fs.azurebfs.oauth2.ClientCredsTokenProvider",
  "fs.azure.account.oauth2.client.id": "<your-service-principal-id>",
  "fs.azure.account.oauth2.client.secret": "<your-secret>",
  "fs.azure.account.oauth2.client.endpoint": "https://login.microsoftonline.com/<tenant-id>/oauth2/token"
}

dbutils.fs.mount(
  source = f"abfss://{container}@{storage_account}.dfs.core.windows.net/",
  mount_point = mount_point,
  extra_configs = configs
)
```

### 3. Access Synapse Analytics

```bash
# Get Synapse workspace name
terraform output synapse_workspace_name

# Open Synapse Studio
# Navigate to: https://web.azuresynapse.net
```

Configure Synapse:
- Create external tables pointing to Data Lake
- Set up SQL views and stored procedures
- Configure data integration pipelines
- Set up Power BI integration

### 4. Configure Data Pipeline Flow

**Typical workflow:**

1. **Data Ingestion** (Data Factory)
   - Ingest raw data to `landing` container
   - Move malformed data to `malformed` container
   - Log all ingestion activities

2. **Data Transformation** (Databricks)
   - Read from `landing` container
   - Clean and validate data
   - Apply business logic transformations
   - Write to `interim` container

3. **Data Aggregation** (Databricks)
   - Read from `interim` container
   - Perform aggregations and joins
   - Create final datasets
   - Write to `datawarehouse` container

4. **Data Warehouse** (Synapse)
   - Create external tables on `datawarehouse` container
   - Serve queries to BI tools
   - Generate reports and dashboards

## Customization

### Change Databricks SKU

Edit `databricks_sku` in `terraform.tfvars`:

```hcl
databricks_sku = "premium"  # For advanced features like RBAC
```

### Change Synapse SQL Pool Size

Edit `synapse_sql_pool_sku` for different performance tiers:

```hcl
synapse_sql_pool_sku = "DW500c"  # Higher performance
```

Available SKUs: DW100c, DW200c, DW300c, DW400c, DW500c, DW1000c, DW1500c, DW2000c, DW2500c, DW3000c

### Add More Data Lake Containers

Add to `main.tf`:

```hcl
resource "azurerm_storage_data_lake_gen2_filesystem" "archive" {
  name               = "archive"
  storage_account_id = azurerm_storage_account.datalake.id
}
```

### Add Event Hub for Streaming Data

Extend the architecture with real-time streaming:

```hcl
resource "azurerm_eventhub_namespace" "main" {
  name                = "${var.prefix}-eventhub"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  sku                 = "Standard"
  capacity            = 1
}
```

## Cleanup

To destroy all resources created by Terraform:

```bash
terraform destroy
```

Type `yes` when prompted to confirm deletion.

## Security Best Practices

✅ **Implemented in this configuration:**

- **Managed Identities**: All services use managed identities (no passwords)
- **RBAC**: Proper role assignments between services
- **Key Vault**: Secrets stored securely
- **Private Endpoints**: Consider adding for production (see below)

🔒 **Additional recommendations for production:**

1. **Use Private Endpoints**
   ```hcl
   # Add private endpoints for each service
   # This keeps traffic within Azure network
   ```

2. **Restrict Synapse Firewall**
   ```hcl
   # Replace the "AllowAll" rule with specific IPs
   # Only allow your organization's IP ranges
   ```

3. **Enable Azure Defender**
   ```bash
   az security pricing create --name SqlServers --tier Standard
   az security pricing create --name StorageAccounts --tier Standard
   ```

4. **Enable Diagnostic Logs**
   ```hcl
   # Add Log Analytics workspace
   # Send all logs to central location
   ```

5. **Use Customer-Managed Keys**
   ```hcl
   # Encrypt data with your own keys in Key Vault
   ```

6. **Network Isolation**
   - Deploy services in Virtual Network
   - Use Private Link for all services
   - Disable public access

## Cost Optimization

💰 **Cost considerations:**

| Service | Default SKU | Monthly Cost (Est.) | Optimization Tips |
|---------|-------------|---------------------|-------------------|
| Data Lake Storage | Standard LRS | $0.02/GB | Use lifecycle policies, delete old data |
| Data Factory | Pay-per-use | Variable | Optimize pipeline runs, use triggers wisely |
| Databricks | Standard | $0.40/DBU + VM | Use autoscaling clusters, pause when not in use |
| Synapse SQL Pool | DW100c | ~$1,200 | **Pause when not querying** (saves 100% compute) |
| Key Vault | Standard | $0.03/10k ops | Minimal cost |

**Total Estimated Monthly Cost**: $1,500 - $3,000 (varies by usage)

### Cost-Saving Tips

1. **Pause Synapse SQL Pool when not in use**
   ```bash
   az synapse sql pool pause --name <pool-name> --workspace-name <workspace-name> --resource-group <rg-name>
   ```

2. **Use Databricks Autoscaling**
   - Set min workers to 1, max to desired limit
   - Automatically scales down during idle periods

3. **Set up Auto-Pause for Databricks clusters**
   - Configure 10-30 minute inactivity timeout

4. **Use Azure Hybrid Benefit** if you have SQL Server licenses

5. **Implement Data Lifecycle Policies**
   ```hcl
   # Move old data to cool/archive tiers
   # Delete after retention period
   ```

6. **Monitor with Cost Management**
   ```bash
   az consumption usage list --start-date 2025-01-01 --end-date 2025-01-31
   ```

## Monitoring and Observability

### Enable Monitoring

1. **Azure Monitor**
   - Set up alerts for pipeline failures
   - Monitor data ingestion rates
   - Track query performance

2. **Application Insights** (optional)
   - Add to Data Factory for detailed telemetry
   - Track pipeline execution times

3. **Log Analytics**
   ```bash
   # Create workspace
   az monitor log-analytics workspace create --resource-group <rg> --workspace-name <name>
   
   # Link services to workspace
   ```

### Key Metrics to Monitor

- Data Factory: Pipeline success rate, execution duration
- Databricks: Cluster utilization, job failures
- Synapse: Query performance, DWU usage
- Data Lake: Storage capacity, ingress/egress

## Troubleshooting

### Authentication Issues

```bash
# Verify Azure login
az login
az account show
az account set --subscription "<subscription-id>"

# Check current user
az account show --query user
```

### Resource Naming Conflicts

Storage accounts must be globally unique. If you get errors:

```bash
# Change the prefix to something unique
# Edit terraform.tfvars
prefix = "myunique"  # Use 3-6 characters
```

### Synapse SQL Pool Won't Create

Ensure your password meets complexity requirements:
- Minimum 8 characters
- Contains uppercase letters (A-Z)
- Contains lowercase letters (a-z)
- Contains digits (0-9)
- Contains special characters (!@#$%^&*)

### Databricks Workspace Access Issues

```bash
# Verify you have Contributor role
az role assignment list --assignee <your-email> --all
```

### Data Factory Can't Access Data Lake

Check managed identity permissions:

```bash
# Verify role assignment
az role assignment list --scope /subscriptions/<sub-id>/resourceGroups/<rg>/providers/Microsoft.Storage/storageAccounts/<storage-name>
```

### Terraform State Lock Issues

```bash
# If state is locked
terraform force-unlock <lock-id>

# Or use backend with state locking
```

## Quick Links

- 🚀 **[Quick Start Guide](QUICKSTART.md)** - Deploy in 5 minutes
- 🏗️ **[Architecture Diagram](ARCHITECTURE.md)** - Detailed architecture
- 📝 **Examples Folder**:
  - [Data Factory Pipeline Template](examples/data-factory-pipeline.json)
  - [Databricks Transformation Notebook](examples/databricks-transformation-notebook.py)
  - [Synapse SQL Scripts](examples/synapse-sql-scripts.sql)

## Automated Deployment

Use the provided deployment script for automated setup:

```bash
# Make the script executable (already done)
chmod +x deploy.sh

# Run the deployment
./deploy.sh
```

The script will:
1. ✅ Check prerequisites (Azure CLI, Terraform)
2. ✅ Verify Azure login
3. ✅ Create terraform.tfvars from template
4. ✅ Initialize Terraform
5. ✅ Validate configuration
6. ✅ Show deployment plan
7. ✅ Deploy infrastructure
8. ✅ Display access URLs and next steps

## Related Azure Documentation

- [Azure Data Factory Documentation](https://docs.microsoft.com/azure/data-factory/)
- [Azure Databricks Documentation](https://docs.microsoft.com/azure/databricks/)
- [Azure Synapse Analytics Documentation](https://docs.microsoft.com/azure/synapse-analytics/)
- [Azure Data Lake Storage Gen2](https://docs.microsoft.com/azure/storage/blobs/data-lake-storage-introduction)
- [Terraform Azure Provider](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)

## Contributing

Contributions are welcome! Please feel free to:
- Report issues
- Suggest enhancements
- Submit pull requests
- Share your use cases

## License

This project is provided as-is for demonstration purposes.

## Support

If you encounter issues:

1. Check the [QUICKSTART.md](QUICKSTART.md) troubleshooting section
2. Review Terraform logs: `terraform.log`
3. Check Azure Activity Log in Azure Portal
4. Verify RBAC permissions: `az role assignment list`

## Acknowledgments

Built with:
- ⚡ Terraform by HashiCorp
- ☁️ Microsoft Azure
- 🤖 GitHub Copilot assistance

---

**Ready to deploy?** Start with the [Quick Start Guide](QUICKSTART.md) or run `./deploy.sh`
