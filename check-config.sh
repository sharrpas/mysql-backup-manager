#!/bin/bash

###############################################################################
# Test Configuration Checker
# Validates your .env configuration before running backups
###############################################################################

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo -e "${GREEN}=== Configuration Checker ===${NC}"
echo ""

# Check if .env exists
if [ ! -f "$SCRIPT_DIR/.env" ]; then
    echo -e "${RED}✗ .env file not found!${NC}"
    echo "Please run ./setup.sh first or copy .env.example to .env"
    exit 1
fi

echo -e "${GREEN}✓ .env file found${NC}"

# Load environment variables
source "$SCRIPT_DIR/.env"

# Check required variables
echo ""
echo "Checking configuration..."
echo ""

errors=0

check_var() {
    var_name=$1
    var_value=${!var_name}

    if [ -z "$var_value" ]; then
        echo -e "${RED}✗ $var_name is not set${NC}"
        ((errors++))
    else
        # Mask sensitive values
        if [[ $var_name == *"PASSWORD"* ]] || [[ $var_name == *"TOKEN"* ]]; then
            echo -e "${GREEN}✓ $var_name is set${NC} (hidden)"
        else
            echo -e "${GREEN}✓ $var_name = $var_value${NC}"
        fi
    fi
}

check_var "MYSQL_HOST"
check_var "MYSQL_PORT"
check_var "MYSQL_USER"
check_var "MYSQL_PASSWORD"
check_var "DATABASES"
check_var "BACKUP_DIR"
check_var "BACKUP_RETENTION_DAYS"

# Check if BACKUP_DIR is problematic
if [[ "$BACKUP_DIR" == /* ]]; then
    # It's an absolute path
    REAL_BACKUP_DIR=$(cd "$BACKUP_DIR" 2>/dev/null && pwd || echo "$BACKUP_DIR")
    REAL_SCRIPT_DIR=$(cd "$SCRIPT_DIR" && pwd)

    if [[ "$REAL_BACKUP_DIR" != "$REAL_SCRIPT_DIR"* ]]; then
        echo -e "${RED}✗ WARNING: BACKUP_DIR ($BACKUP_DIR) is outside the repository${NC}"
        echo -e "${YELLOW}  This will prevent git commits from working.${NC}"
        echo -e "${YELLOW}  Please set BACKUP_DIR to a relative path like: ./backups${NC}"
        ((errors++))
    fi
else
    echo -e "${GREEN}✓ BACKUP_DIR is a relative path (recommended)${NC}"
fi

check_var "GITHUB_REPO_URL"
check_var "GITHUB_BRANCH"
check_var "GIT_USER_NAME"
check_var "GIT_USER_EMAIL"

echo ""

# Check optional variables
if [ -z "$GITHUB_TOKEN" ]; then
    echo -e "${YELLOW}! GITHUB_TOKEN is not set (optional, but recommended for automation)${NC}"
else
    echo -e "${GREEN}✓ GITHUB_TOKEN is set${NC}"
fi

echo ""

# Check if mysqldump is available
if command -v mysqldump &> /dev/null; then
    echo -e "${GREEN}✓ mysqldump is installed${NC}"
else
    echo -e "${RED}✗ mysqldump is not installed${NC}"
    echo "  Install with: sudo apt-get install mysql-client"
    ((errors++))
fi

# Check if git is available
if command -v git &> /dev/null; then
    echo -e "${GREEN}✓ git is installed${NC}"
else
    echo -e "${RED}✗ git is not installed${NC}"
    echo "  Install with: sudo apt-get install git"
    ((errors++))
fi

# Check if gzip is available
if command -v gzip &> /dev/null; then
    echo -e "${GREEN}✓ gzip is installed${NC}"
else
    echo -e "${RED}✗ gzip is not installed${NC}"
    echo "  Install with: sudo apt-get install gzip"
    ((errors++))
fi

echo ""

if [ $errors -eq 0 ]; then
    echo -e "${GREEN}=== All checks passed! ===${NC}"
    echo "You can now run: ./backup.sh"
else
    echo -e "${RED}=== Found $errors error(s) ===${NC}"
    echo "Please fix the errors above before running the backup script."
    exit 1
fi

