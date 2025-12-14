#!/bin/bash

# Azure Data Analytics Platform - Deployment Script
# This script automates the deployment of the Terraform infrastructure

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_header() {
    echo ""
    echo -e "${BLUE}════════════════════════════════════════${NC}"
    echo -e "${BLUE}  $1${NC}"
    echo -e "${BLUE}════════════════════════════════════════${NC}"
    echo ""
}

# Check prerequisites
check_prerequisites() {
    print_header "Checking Prerequisites"
    
    # Check if Azure CLI is installed
    if ! command -v az &> /dev/null; then
        print_error "Azure CLI is not installed. Please install it first."
        echo "Visit: https://docs.microsoft.com/en-us/cli/azure/install-azure-cli"
        exit 1
    fi
    print_success "Azure CLI is installed"
    
    # Check if Terraform is installed
    if ! command -v terraform &> /dev/null; then
        print_error "Terraform is not installed. Please install it first."
        echo "Visit: https://www.terraform.io/downloads"
        exit 1
    fi
    print_success "Terraform is installed ($(terraform version | head -n 1))"
    
    # Check Azure login status
    if ! az account show &> /dev/null; then
        print_warning "Not logged in to Azure. Attempting login..."
        az login
    fi
    print_success "Logged in to Azure"
    
    # Display current subscription
    SUBSCRIPTION=$(az account show --query name -o tsv)
    print_info "Current subscription: $SUBSCRIPTION"
}

# Create terraform.tfvars if it doesn't exist
setup_tfvars() {
    print_header "Setting Up Configuration"
    
    if [ -f "terraform.tfvars" ]; then
        print_warning "terraform.tfvars already exists. Skipping creation."
        return
    fi
    
    print_info "Creating terraform.tfvars from example..."
    cp terraform.tfvars.example terraform.tfvars
    
    print_warning "Please edit terraform.tfvars with your values:"
    echo "  - Set a unique 'prefix' (3-6 characters)"
    echo "  - Set a secure 'synapse_sql_admin_password'"
    echo ""
    read -p "Do you want to edit terraform.tfvars now? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        ${EDITOR:-nano} terraform.tfvars
    fi
}

# Initialize Terraform
init_terraform() {
    print_header "Initializing Terraform"
    
    if [ -d ".terraform" ]; then
        print_info "Terraform already initialized"
    else
        print_info "Running terraform init..."
        terraform init
        print_success "Terraform initialized"
    fi
}

# Validate Terraform configuration
validate_terraform() {
    print_header "Validating Configuration"
    
    print_info "Running terraform validate..."
    if terraform validate; then
        print_success "Configuration is valid"
    else
        print_error "Configuration validation failed"
        exit 1
    fi
}

# Plan Terraform deployment
plan_terraform() {
    print_header "Planning Deployment"
    
    print_info "Running terraform plan..."
    terraform plan -out=tfplan
    print_success "Plan created successfully"
    
    echo ""
    read -p "Review the plan above. Continue with deployment? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_warning "Deployment cancelled by user"
        exit 0
    fi
}

# Apply Terraform configuration
apply_terraform() {
    print_header "Deploying Infrastructure"
    
    print_info "This will take approximately 10-15 minutes..."
    print_info "Running terraform apply..."
    
    if terraform apply tfplan; then
        print_success "Infrastructure deployed successfully!"
    else
        print_error "Deployment failed"
        exit 1
    fi
}

# Display outputs
show_outputs() {
    print_header "Deployment Summary"
    
    echo ""
    terraform output next_steps
    echo ""
    
    print_info "To view all outputs: terraform output"
    print_info "To view specific output: terraform output <output_name>"
    
    echo ""
    print_warning "IMPORTANT: Synapse SQL Pool is running and incurring costs!"
    print_warning "To pause it: az synapse sql pool pause --name <pool-name> --workspace-name <workspace-name> --resource-group <rg-name>"
}

# Main deployment flow
main() {
    print_header "Azure Data Analytics Platform Deployment"
    
    check_prerequisites
    setup_tfvars
    init_terraform
    validate_terraform
    plan_terraform
    apply_terraform
    show_outputs
    
    print_success "Deployment completed successfully! 🎉"
}

# Run main function
main
