# Quick Start Guide

## Prerequisites Checklist

Before deploying, ensure you have:

- [ ] Azure CLI installed and logged in (`az login`)
- [ ] Terraform installed (>= 1.0)
- [ ] Azure subscription with Contributor/Owner permissions
- [ ] Decided on a unique prefix (3-6 characters)

## 5-Minute Deployment

### Step 1: Configure Variables

```bash
# Copy the example file
cp terraform.tfvars.example terraform.tfvars

# Edit with your preferred editor
nano terraform.tfvars
```

**Minimum required changes:**
```hcl
prefix = "myapp"  # Change to something unique
synapse_sql_admin_password = "YourSecurePassword123!"  # Change this!
```

### Step 2: Initialize and Deploy

```bash
# Initialize Terraform
terraform init

# Preview changes
terraform plan

# Deploy (takes ~10-15 minutes)
terraform apply -auto-approve
```

### Step 3: Get Your Endpoints

```bash
# View all outputs
terraform output

# Get specific values
terraform output databricks_workspace_url
terraform output synapse_workspace_name
terraform output datalake_storage_account_name
```

## Next Steps After Deployment

### 1. Access Databricks (2 minutes)

```bash
# Open Databricks
open "https://$(terraform output -raw databricks_workspace_url)"
```

**In Databricks:**
1. Click "Create" → "Cluster"
2. Name: `transform-cluster`
3. Runtime: `11.3 LTS` or later
4. Node type: `Standard_DS3_v2` (or smaller for dev)
5. Click "Create Cluster"

### 2. Access Synapse Studio (1 minute)

```bash
# Open Synapse Studio
open "https://web.azuresynapse.net"
```

**In Synapse:**
1. Select your workspace
2. Go to "Develop" → "SQL scripts"
3. Connect to your SQL Pool
4. Run example queries from `examples/synapse-sql-scripts.sql`

### 3. Access Data Factory (1 minute)

```bash
# Open Data Factory Studio
open "https://adf.azure.com"
```

**In Data Factory:**
1. Select your factory
2. Go to "Author" → "Pipelines"
3. Create your first pipeline using the template in `examples/`

### 4. Verify Data Lake Containers

```bash
# Get storage account name
STORAGE_ACCOUNT=$(terraform output -raw datalake_storage_account_name)

# List containers
az storage fs list --account-name $STORAGE_ACCOUNT --auth-mode login

# Expected output: landing, malformed, interim, datawarehouse
```

## Common First-Time Tasks

### Upload Sample Data to Landing

```bash
# Get storage account name
STORAGE_ACCOUNT=$(terraform output -raw datalake_storage_account_name)

# Upload a file
az storage fs file upload \
  --account-name $STORAGE_ACCOUNT \
  --file-system landing \
  --path sample-data/test.csv \
  --source ./local-file.csv \
  --auth-mode login
```

### Pause Synapse SQL Pool (Save Costs!)

```bash
# Get details
RG=$(terraform output -raw resource_group_name)
WORKSPACE=$(terraform output -raw synapse_workspace_name)
POOL=$(terraform output -raw synapse_sql_pool_name)

# Pause the SQL Pool
az synapse sql pool pause \
  --name $POOL \
  --workspace-name $WORKSPACE \
  --resource-group $RG
```

### Resume Synapse SQL Pool

```bash
# Resume when needed
az synapse sql pool resume \
  --name $POOL \
  --workspace-name $WORKSPACE \
  --resource-group $RG
```

## Troubleshooting Quick Fixes

### Problem: "Storage account name already exists"

**Solution:** Change your prefix to something more unique
```bash
# Edit terraform.tfvars
prefix = "mycompany123"  # Use something unique
```

### Problem: "Invalid password for Synapse SQL"

**Solution:** Use a complex password
```hcl
synapse_sql_admin_password = "Complex@Pass123!"
# Must have: uppercase, lowercase, numbers, special chars, 8+ chars
```

### Problem: "Permission denied"

**Solution:** Verify Azure login and permissions
```bash
az login
az account show
az role assignment list --assignee $(az account show --query user.name -o tsv)
```

### Problem: "Terraform state is locked"

**Solution:** Force unlock (use carefully!)
```bash
terraform force-unlock <LOCK_ID>
```

## Estimated Costs

| Scenario | Monthly Cost |
|----------|--------------|
| **Dev/Test** (paused SQL Pool most of time) | $50-$200 |
| **Small Production** (SQL Pool runs 8hrs/day) | $800-$1,500 |
| **Full Production** (SQL Pool always on) | $2,000-$4,000 |

**Cost-saving tips:**
- Pause Synapse SQL Pool when not querying: **Saves ~$1,200/month**
- Use autoscaling Databricks clusters: **Saves 30-50%**
- Set up auto-shutdown for Databricks clusters: **Essential**
- Use lifecycle policies on Data Lake: **Saves on storage**

## Clean Up (Destroy Resources)

```bash
# Destroy everything
terraform destroy

# Or destroy specific resources
terraform destroy -target=azurerm_synapse_sql_pool.main
```

⚠️ **Warning:** This will delete all data! Export important data first.

## Getting Help

1. **Terraform Issues**: Check `terraform.log`
2. **Azure Issues**: Check Azure Portal → Activity Log
3. **Permissions**: Run `az role assignment list`
4. **Costs**: Check Azure Portal → Cost Management

## Useful Commands Reference

```bash
# Show current state
terraform show

# List all resources
terraform state list

# Get specific output
terraform output <output_name>

# Refresh state
terraform refresh

# Format code
terraform fmt

# Validate configuration
terraform validate

# Show plan with details
terraform plan -out=tfplan

# Apply specific plan
terraform apply tfplan
```

## What's Next?

1. ✅ Deploy infrastructure (you just did this!)
2. 📊 Upload sample data to Landing container
3. 📝 Create Databricks notebook for transformation
4. 🔄 Create Data Factory pipeline
5. 📈 Set up Synapse SQL queries
6. 📱 Connect Power BI or Tableau
7. 🔔 Configure alerts and monitoring

---

**Need more help?** Check the full [README.md](README.md) or [ARCHITECTURE.md](ARCHITECTURE.md)
