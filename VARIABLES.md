# Terraform Variables Reference

## Required Variables

These variables should be customized in `terraform.tfvars`:

### resource_group_name
- **Type:** string
- **Default:** `rg-data-analytics-platform`
- **Description:** Name of the Azure resource group that will contain all resources
- **Example:** `rg-data-analytics-prod`

### location
- **Type:** string
- **Default:** `East US`
- **Description:** Azure region where resources will be deployed
- **Valid options:** Any Azure region
- **Popular choices:**
  - `East US` - US East Coast
  - `West US 2` - US West Coast
  - `West Europe` - Europe
  - `Southeast Asia` - Asia Pacific
  - `Australia East` - Australia

### prefix
- **Type:** string
- **Default:** `dap`
- **Description:** Short prefix (3-6 characters) for resource names
- **Important:** Must be globally unique for storage accounts
- **Constraints:**
  - 3-6 characters recommended
  - Lowercase letters and numbers only
  - No special characters or spaces
- **Example:** `myapp`, `prod`, `dev123`

## Service-Specific Variables

### databricks_sku
- **Type:** string
- **Default:** `standard`
- **Valid options:**
  - `standard` - Basic features ($)
  - `premium` - Advanced features including RBAC, audit logs ($$)
  - `trial` - Free trial (limited time)
- **Recommendation:** Use `standard` for dev/test, `premium` for production

### synapse_sql_admin_username
- **Type:** string
- **Default:** `sqladmin`
- **Description:** Administrator username for Synapse SQL Pool
- **Constraints:**
  - Cannot be: `admin`, `administrator`, `sa`, `root`, `guest`
  - 1-128 characters
  - Cannot start with number or symbol

### synapse_sql_admin_password
- **Type:** string (sensitive)
- **Default:** `P@ssw0rd123!` ⚠️ **CHANGE THIS!**
- **Description:** Administrator password for Synapse SQL Pool
- **Requirements:**
  - Minimum 8 characters
  - Maximum 128 characters
  - Must contain characters from three of these categories:
    - Uppercase letters (A-Z)
    - Lowercase letters (a-z)
    - Numbers (0-9)
    - Special characters (!@#$%^&*()_+-=[]{}|;:,.<>?)
- **Example:** `MySecurePass123!`
- **⚠️ Security:** Store in environment variable or Azure Key Vault in production

### synapse_sql_pool_sku
- **Type:** string
- **Default:** `DW100c`
- **Description:** Performance tier for Synapse Dedicated SQL Pool
- **Valid options:**
  - `DW100c` - 100 cDWU (~$1,200/month) - Dev/Test
  - `DW200c` - 200 cDWU (~$2,400/month)
  - `DW300c` - 300 cDWU (~$3,600/month)
  - `DW400c` - 400 cDWU (~$4,800/month)
  - `DW500c` - 500 cDWU (~$6,000/month)
  - `DW1000c` - 1000 cDWU (~$12,000/month)
  - Up to `DW30000c` for very large workloads
- **Note:** Can be paused to stop compute charges
- **Tip:** Start small and scale up as needed

## Tags

### tags
- **Type:** map(string)
- **Default:**
  ```hcl
  {
    Environment  = "Development"
    ManagedBy    = "Terraform"
    Project      = "Data-Analytics-Platform"
    Architecture = "Data-Lake-Databricks-Synapse"
  }
  ```
- **Description:** Tags applied to all resources for organization and cost tracking
- **Recommended additions:**
  - `CostCenter` - For chargeback
  - `Owner` - Responsible team/person
  - `ExpirationDate` - For temporary environments
  - `BackupPolicy` - Backup requirements
  - `Compliance` - Compliance requirements (HIPAA, PCI, etc.)

## Example terraform.tfvars

### Minimal Configuration
```hcl
prefix = "myapp"
synapse_sql_admin_password = "MySecure@Password123"
```

### Development Environment
```hcl
resource_group_name        = "rg-data-dev"
location                   = "East US"
prefix                     = "dev"
databricks_sku             = "standard"
synapse_sql_admin_username = "sqladmin"
synapse_sql_admin_password = "DevPassword123!"
synapse_sql_pool_sku       = "DW100c"

tags = {
  Environment = "Development"
  ManagedBy   = "Terraform"
  Project     = "Data-Analytics"
  Owner       = "Data-Team"
  CostCenter  = "Engineering"
}
```

### Production Environment
```hcl
resource_group_name        = "rg-data-prod"
location                   = "East US 2"
prefix                     = "prod"
databricks_sku             = "premium"
synapse_sql_admin_username = "sqladmin"
synapse_sql_admin_password = "Pr0d!SecureP@ssw0rd2025"
synapse_sql_pool_sku       = "DW500c"

tags = {
  Environment    = "Production"
  ManagedBy      = "Terraform"
  Project        = "Data-Analytics-Platform"
  Owner          = "Data-Engineering-Team"
  CostCenter     = "Analytics"
  Compliance     = "SOC2"
  BackupPolicy   = "Daily"
  BusinessUnit   = "Corporate"
  SupportContact = "data-team@company.com"
}
```

## Using Environment Variables

For sensitive values, use environment variables:

```bash
# Set environment variables
export TF_VAR_synapse_sql_admin_password="YourSecurePassword123!"
export TF_VAR_prefix="myapp"

# Run terraform without exposing secrets in files
terraform plan
terraform apply
```

## Variable Validation

The configuration includes validation rules:

1. **databricks_sku:** Must be `standard`, `premium`, or `trial`
2. **prefix:** Should be kept short (3-6 chars) to avoid resource name length issues
3. **synapse_sql_admin_password:** Azure enforces complexity requirements

## Cost Estimation by Configuration

| Configuration | Monthly Estimate |
|---------------|------------------|
| **Minimal (DW100c, Standard Databricks)** | $1,200 - $1,500 |
| **Medium (DW300c, Premium Databricks)** | $3,600 - $4,500 |
| **Large (DW1000c, Premium Databricks)** | $12,000 - $15,000 |

**Cost-saving tips:**
- Pause Synapse SQL Pool when not in use (saves ~$1,200/month for DW100c)
- Use Databricks autoscaling
- Implement data lifecycle policies
- Use reserved capacity for predictable workloads

## Security Best Practices

1. **Never commit terraform.tfvars with real passwords**
   - It's in `.gitignore` by default
   
2. **Use Azure Key Vault for secrets in production**
   ```bash
   az keyvault secret set --vault-name <vault> --name synapse-password --value "password"
   ```

3. **Use managed identities** (already configured)
   - No passwords needed between Azure services

4. **Rotate passwords regularly**
   ```bash
   # Update password
   terraform apply -var="synapse_sql_admin_password=NewPassword123!"
   ```

5. **Use Azure RBAC** for access control
   ```bash
   # Grant user access to Synapse
   az synapse role assignment create \
     --workspace-name <workspace> \
     --role "Synapse Administrator" \
     --assignee user@company.com
   ```
