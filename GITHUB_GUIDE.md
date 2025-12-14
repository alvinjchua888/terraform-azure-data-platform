# GitHub Upload Guide

This guide will walk you through uploading your Azure Data Analytics Platform Terraform project to GitHub.

## Prerequisites

- GitHub account (create one at https://github.com if you don't have one)
- Git installed on your machine
- GitHub CLI (optional, but recommended)

## Option 1: Using GitHub CLI (Recommended - Easiest)

### Step 1: Install GitHub CLI (if not already installed)

```bash
# On macOS using Homebrew
brew install gh

# Verify installation
gh --version
```

### Step 2: Authenticate with GitHub

```bash
# Login to GitHub
gh auth login

# Follow the prompts:
# - Choose "GitHub.com"
# - Choose "HTTPS" or "SSH" (HTTPS is easier)
# - Authenticate in browser
```

### Step 3: Initialize Git and Create GitHub Repo

```bash
# Navigate to your project
cd /Users/alvinchua/terraform-azure-githubcopilot

# Initialize git repository
git init

# Add all files
git add .

# Create initial commit
git commit -m "Initial commit: Azure Data Analytics Platform with Terraform"

# Create GitHub repository and push
gh repo create terraform-azure-data-platform --public --source=. --push

# Or for private repository:
# gh repo create terraform-azure-data-platform --private --source=. --push
```

Done! Your repository is now on GitHub! 🎉

---

## Option 2: Using Git Command Line (Manual)

### Step 1: Check Git Installation

```bash
# Check if git is installed
git --version

# If not installed on macOS:
brew install git
```

### Step 2: Configure Git (First Time Only)

```bash
# Set your name and email
git config --global user.name "Your Name"
git config --global user.email "your.email@example.com"

# Verify configuration
git config --list
```

### Step 3: Initialize Local Git Repository

```bash
# Navigate to your project
cd /Users/alvinchua/terraform-azure-githubcopilot

# Initialize git repository
git init

# Check status
git status
```

### Step 4: Stage and Commit Files

```bash
# Add all files (respects .gitignore)
git add .

# Verify what will be committed
git status

# Create initial commit
git commit -m "Initial commit: Azure Data Analytics Platform with Terraform"
```

### Step 5: Create GitHub Repository

1. Go to https://github.com
2. Click the "+" icon in top right → "New repository"
3. Repository name: `terraform-azure-data-platform`
4. Description: `Azure Data Analytics Platform with Data Lake, Data Factory, Databricks, and Synapse Analytics`
5. Choose "Public" or "Private"
6. **DO NOT** initialize with README (we already have one)
7. **DO NOT** add .gitignore (we already have one)
8. Click "Create repository"

### Step 6: Link Local Repo to GitHub and Push

```bash
# Add GitHub as remote (replace YOUR-USERNAME with your GitHub username)
git remote add origin https://github.com/YOUR-USERNAME/terraform-azure-data-platform.git

# Verify remote
git remote -v

# Push code to GitHub
git branch -M main
git push -u origin main
```

Enter your GitHub username and password (or personal access token) when prompted.

---

## Option 3: Using GitHub Desktop (GUI)

### Step 1: Install GitHub Desktop

Download from: https://desktop.github.com

### Step 2: Add Repository

1. Open GitHub Desktop
2. File → Add Local Repository
3. Browse to: `/Users/alvinchua/terraform-azure-githubcopilot`
4. Click "Add Repository"

### Step 3: Publish to GitHub

1. Click "Publish repository" button
2. Name: `terraform-azure-data-platform`
3. Description: `Azure Data Analytics Platform with Terraform`
4. Choose Public or Private
5. Uncheck "Keep this code private" if you want it public
6. Click "Publish Repository"

Done! 🎉

---

## Verify Upload

After pushing, verify your repository:

```bash
# Check repository URL
git remote -v

# View repository in browser
gh repo view --web

# Or manually visit:
# https://github.com/YOUR-USERNAME/terraform-azure-data-platform
```

---

## Important: Security Check

Before pushing, verify sensitive files are NOT included:

```bash
# Check what will be committed
git status

# Verify .gitignore is working
cat .gitignore

# These files should NOT appear in git status:
# ✗ terraform.tfvars (contains passwords!)
# ✗ *.tfstate
# ✗ .terraform/
```

If `terraform.tfvars` appears, it means it was added before `.gitignore`. Remove it:

```bash
# Remove from git (keeps local file)
git rm --cached terraform.tfvars

# Commit the removal
git commit -m "Remove terraform.tfvars from git"

# Push the change
git push
```

---

## Add a Repository Description and Topics

### Using GitHub CLI

```bash
gh repo edit --description "Azure Data Analytics Platform with Data Lake, Data Factory, Databricks, and Synapse Analytics - Infrastructure as Code"

gh repo edit --add-topic terraform
gh repo edit --add-topic azure
gh repo edit --add-topic databricks
gh repo edit --add-topic synapse-analytics
gh repo edit --add-topic data-lake
gh repo edit --add-topic data-factory
gh repo edit --add-topic infrastructure-as-code
```

### Using GitHub Web Interface

1. Go to your repository
2. Click "⚙️ Settings"
3. Add topics: `terraform`, `azure`, `databricks`, `synapse-analytics`, `data-lake`, `data-factory`
4. Add description
5. Click "Save"

---

## Create a Better README for GitHub

Add a badge and improve the README:

```bash
# Add GitHub badge at the top of README.md
```

I'll add this for you automatically in the next section.

---

## Set Up Branch Protection (Optional)

For team projects, protect your main branch:

```bash
# Using GitHub CLI
gh api repos/:owner/:repo/branches/main/protection \
  --method PUT \
  --field required_status_checks='{"strict":true,"contexts":[]}' \
  --field enforce_admins=false \
  --field required_pull_request_reviews='{"required_approving_review_count":1}'
```

---

## Enable GitHub Actions (Optional)

Add `.github/workflows/terraform.yml` for automated validation:

```yaml
name: Terraform Validation

on:
  push:
    branches: [ main ]
  pull_request:
    branches: [ main ]

jobs:
  validate:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: hashicorp/setup-terraform@v2
      - run: terraform init -backend=false
      - run: terraform validate
      - run: terraform fmt -check
```

---

## Clone on Another Machine

To work on this project from another computer:

```bash
# Clone the repository
git clone https://github.com/YOUR-USERNAME/terraform-azure-data-platform.git

# Navigate to directory
cd terraform-azure-data-platform

# Create terraform.tfvars from example
cp terraform.tfvars.example terraform.tfvars

# Edit with your values
nano terraform.tfvars

# Initialize terraform
terraform init
```

---

## Common Git Commands for Future Updates

```bash
# Check status
git status

# Add changes
git add .

# Commit changes
git commit -m "Description of changes"

# Push to GitHub
git push

# Pull latest changes
git pull

# View commit history
git log --oneline

# Create a new branch
git checkout -b feature/new-feature

# Switch branches
git checkout main

# Merge a branch
git merge feature/new-feature
```

---

## Troubleshooting

### Issue: "Permission denied (publickey)"

**Solution:** Set up SSH key or use HTTPS

```bash
# Use HTTPS instead
git remote set-url origin https://github.com/YOUR-USERNAME/terraform-azure-data-platform.git
```

### Issue: "fatal: repository not found"

**Solution:** Check repository name and your GitHub username

```bash
# Verify remote URL
git remote -v

# Update if incorrect
git remote set-url origin https://github.com/CORRECT-USERNAME/terraform-azure-data-platform.git
```

### Issue: "Updates were rejected"

**Solution:** Pull first, then push

```bash
git pull origin main --rebase
git push origin main
```

### Issue: Large files rejected

**Solution:** Remove large files or use Git LFS

```bash
# Find large files
find . -type f -size +50M

# Remove from git if accidentally added
git rm --cached "Screenshot 2025-12-14 at 2.39.39 PM.jpeg"
git commit -m "Remove large screenshot"
```

---

## Next Steps After Upload

1. ✅ Add a LICENSE file (MIT, Apache 2.0, etc.)
2. ✅ Add GitHub repository badges to README
3. ✅ Set up GitHub Issues for tracking
4. ✅ Add CONTRIBUTING.md for collaborators
5. ✅ Enable GitHub Discussions for Q&A
6. ✅ Set up GitHub Projects for task management
7. ✅ Add GitHub Actions for CI/CD

---

## Share Your Repository

Once uploaded, share with:

```bash
# Get repository URL
gh repo view --web

# Or construct URL:
# https://github.com/YOUR-USERNAME/terraform-azure-data-platform
```

Share on:
- LinkedIn
- Twitter
- Reddit (r/terraform, r/azure)
- Dev.to
- HashiCorp Community

---

## Keep Your Repository Updated

```bash
# Regular workflow:
# 1. Make changes to files
# 2. Stage changes
git add .

# 3. Commit with descriptive message
git commit -m "Add monitoring configuration for Synapse"

# 4. Push to GitHub
git push

# That's it!
```

---

**Questions?** Check the Git documentation: https://git-scm.com/doc
