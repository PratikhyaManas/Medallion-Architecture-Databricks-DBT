#!/bin/bash
# Databricks dbt Streaming Platform - Local Setup Script

set -e

echo "=================================="
echo "dbt Streaming Medallion Setup"
echo "=================================="

# Color codes for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check Python version
echo -e "${BLUE}Checking Python version...${NC}"
python_version=$(python3 --version 2>&1 | awk '{print $2}')
echo "Python version: $python_version"

# Create virtual environment
echo -e "${BLUE}Creating Python virtual environment...${NC}"
if [ ! -d "venv" ]; then
    python3 -m venv venv
    echo -e "${GREEN}✓ Virtual environment created${NC}"
else
    echo -e "${YELLOW}Virtual environment already exists${NC}"
fi

# Activate virtual environment
source venv/bin/activate
echo -e "${GREEN}✓ Virtual environment activated${NC}"

# Upgrade pip
echo -e "${BLUE}Upgrading pip...${NC}"
pip install --upgrade pip
echo -e "${GREEN}✓ pip upgraded${NC}"

# Install Python dependencies
echo -e "${BLUE}Installing Python dependencies...${NC}"
pip install -r requirements.txt
echo -e "${GREEN}✓ Dependencies installed${NC}"

# Create .dbt directory
echo -e "${BLUE}Setting up dbt configuration...${NC}"
mkdir -p ~/.dbt

# Check if profiles.yml exists
if [ ! -f ~/.dbt/profiles.yml ]; then
    echo -e "${YELLOW}profiles.yml not found in ~/.dbt/${NC}"
    echo "Please do one of the following:"
    echo "1. Copy profiles.yml to ~/.dbt/: cp profiles.yml ~/.dbt/"
    echo "2. Or manually create ~/.dbt/profiles.yml with your Databricks credentials"
else
    echo -e "${GREEN}✓ profiles.yml found${NC}"
fi

# Create .env file from template
if [ ! -f .env ]; then
    echo -e "${BLUE}Creating .env file from template...${NC}"
    cp .env.example .env
    echo -e "${YELLOW}Please edit .env file with your Databricks credentials${NC}"
    echo -e "${BLUE}nano .env${NC}"
else
    echo -e "${GREEN}✓ .env file already exists${NC}"
fi

# Download dbt packages
echo -e "${BLUE}Downloading dbt packages...${NC}"
dbt deps
echo -e "${GREEN}✓ dbt packages installed${NC}"

# Validate dbt setup
echo -e "${BLUE}Validating dbt setup...${NC}"
dbt debug --profiles-dir ~/.dbt

echo ""
echo "=================================="
echo -e "${GREEN}Setup Complete!${NC}"
echo "=================================="
echo ""
echo "Next steps:"
echo "1. Update your credentials in ~/.dbt/profiles.yml"
echo "2. Update environment variables in .env"
echo "3. Create Databricks resources (catalog, schemas, cluster)"
echo "4. Run: dbt seed --profiles-dir ~/.dbt"
echo "5. Run: dbt run --profiles-dir ~/.dbt"
echo ""
echo "For deployment:"
echo "- Setup GitHub secrets (see DEPLOYMENT.md)"
echo "- Deploy with: databricks bundle deploy --target dev"
echo ""
