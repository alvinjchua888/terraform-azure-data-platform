#!/bin/bash

# Quick GitHub Upload Script
# This script helps you upload your repository to GitHub

set -e

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${BLUE}════════════════════════════════════════${NC}"
echo -e "${BLUE}  Upload to GitHub${NC}"
echo -e "${BLUE}════════════════════════════════════════${NC}"
echo ""

# Check if we're in a git repository
if [ ! -d ".git" ]; then
    echo -e "${YELLOW}Not a git repository. Run this from your project directory.${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Git repository detected${NC}"
echo ""

# Get GitHub username
echo -e "${BLUE}Enter your GitHub username:${NC}"
read GITHUB_USERNAME

if [ -z "$GITHUB_USERNAME" ]; then
    echo "Username cannot be empty!"
    exit 1
fi

# Get repository name
echo -e "${BLUE}Enter repository name (default: terraform-azure-data-platform):${NC}"
read REPO_NAME

if [ -z "$REPO_NAME" ]; then
    REPO_NAME="terraform-azure-data-platform"
fi

# Construct GitHub URL
GITHUB_URL="https://github.com/${GITHUB_USERNAME}/${REPO_NAME}.git"

echo ""
echo -e "${YELLOW}Before continuing:${NC}"
echo "1. Go to https://github.com/new"
echo "2. Repository name: ${REPO_NAME}"
echo "3. Choose Public or Private"
echo "4. DO NOT initialize with README, .gitignore, or license"
echo "5. Click 'Create repository'"
echo ""
echo "Repository URL will be: ${GITHUB_URL}"
echo ""

read -p "Have you created the repository on GitHub? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Please create the repository first, then run this script again."
    exit 0
fi

# Add remote
echo ""
echo -e "${BLUE}Adding GitHub as remote...${NC}"
git remote add origin $GITHUB_URL

# Verify remote
echo -e "${GREEN}✅ Remote added${NC}"
git remote -v

# Push to GitHub
echo ""
echo -e "${BLUE}Pushing to GitHub...${NC}"
git push -u origin main

echo ""
echo -e "${GREEN}════════════════════════════════════════${NC}"
echo -e "${GREEN}  Success! 🎉${NC}"
echo -e "${GREEN}════════════════════════════════════════${NC}"
echo ""
echo "Your repository is now on GitHub:"
echo "https://github.com/${GITHUB_USERNAME}/${REPO_NAME}"
echo ""
echo "Next steps:"
echo "1. Visit your repository on GitHub"
echo "2. Add a description and topics"
echo "3. Share with your team!"
