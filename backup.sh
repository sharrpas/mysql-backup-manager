#!/bin/bash

###############################################################################
# MySQL Database Backup Script
#
# This script:
# - Backs up specified MySQL databases
# - Compresses backups to .gz format
# - Commits backups to GitHub
# - Automatically removes backups older than specified retention period
###############################################################################

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Load environment variables
if [ -f "$SCRIPT_DIR/.env" ]; then
    source "$SCRIPT_DIR/.env"
else
    echo -e "${RED}Error: .env file not found!${NC}"
    echo "Please copy .env.example to .env and configure it."
    exit 1
fi

# Validate required environment variables
required_vars=("MYSQL_HOST" "MYSQL_USER" "MYSQL_PASSWORD" "DATABASES" "BACKUP_DIR" "BACKUP_RETENTION_DAYS" "GITHUB_REPO_URL" "GITHUB_BRANCH" "GIT_USER_NAME" "GIT_USER_EMAIL")

for var in "${required_vars[@]}"; do
    if [ -z "${!var}" ]; then
        echo -e "${RED}Error: Required environment variable $var is not set!${NC}"
        exit 1
    fi
done

# Create backup directory if it doesn't exist
mkdir -p "$BACKUP_DIR"

# Timestamp for backup
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
DATE_DIR=$(date +"%Y-%m-%d")

# Create date-based subdirectory
BACKUP_DATE_DIR="$BACKUP_DIR/$DATE_DIR"
mkdir -p "$BACKUP_DATE_DIR"

echo -e "${GREEN}=== MySQL Database Backup Script ===${NC}"
echo "Timestamp: $(date)"
echo ""

# Convert comma-separated databases to array
IFS=',' read -ra DB_ARRAY <<< "$DATABASES"

# Backup each database
for DB_NAME in "${DB_ARRAY[@]}"; do
    # Trim whitespace
    DB_NAME=$(echo "$DB_NAME" | xargs)

    echo -e "${YELLOW}Backing up database: $DB_NAME${NC}"

    BACKUP_FILE="$BACKUP_DATE_DIR/${DB_NAME}_${TIMESTAMP}.sql.gz"

    # Create backup and compress on the fly
    if mysqldump -h "$MYSQL_HOST" \
                 -P "$MYSQL_PORT" \
                 -u "$MYSQL_USER" \
                 -p"$MYSQL_PASSWORD" \
                 --single-transaction \
                 --quick \
                 --lock-tables=false \
                 "$DB_NAME" | gzip > "$BACKUP_FILE"; then

        BACKUP_SIZE=$(du -h "$BACKUP_FILE" | cut -f1)
        echo -e "${GREEN}✓ Successfully backed up $DB_NAME ($BACKUP_SIZE)${NC}"
    else
        echo -e "${RED}✗ Failed to backup $DB_NAME${NC}"
        exit 1
    fi
done

echo ""
echo -e "${YELLOW}Removing backups older than $BACKUP_RETENTION_DAYS days...${NC}"

# Remove old backups
find "$BACKUP_DIR" -type f -name "*.sql.gz" -mtime +$BACKUP_RETENTION_DAYS -delete

# Remove empty directories
find "$BACKUP_DIR" -type d -empty -delete

echo -e "${GREEN}✓ Cleanup completed${NC}"
echo ""

# Git operations
echo -e "${YELLOW}Committing backups to GitHub...${NC}"

cd "$SCRIPT_DIR"

# Initialize git repo if not already initialized
if [ ! -d ".git" ]; then
    echo "Initializing Git repository..."
    git init
    git config user.name "$GIT_USER_NAME"
    git config user.email "$GIT_USER_EMAIL"
    git remote add origin "$GITHUB_REPO_URL"
else
    # Update git config
    git config user.name "$GIT_USER_NAME"
    git config user.email "$GIT_USER_EMAIL"
fi

# Configure GitHub token authentication if provided
if [ ! -z "$GITHUB_TOKEN" ]; then
    # Extract repo URL without protocol
    REPO_URL_NO_PROTOCOL=$(echo "$GITHUB_REPO_URL" | sed -e 's|https://||' -e 's|http://||')
    # Set up authenticated URL
    git remote set-url origin "https://${GITHUB_TOKEN}@${REPO_URL_NO_PROTOCOL}"
fi

# Add backups to git
git add "$BACKUP_DIR"

# Check if there are changes to commit
if git diff --staged --quiet; then
    echo -e "${YELLOW}No changes to commit${NC}"
else
    # Commit changes
    COMMIT_MESSAGE="Database backup - $(date +'%Y-%m-%d %H:%M:%S')"
    git commit -m "$COMMIT_MESSAGE"

    # Push to GitHub
    echo "Pushing to GitHub..."
    if git push origin "$GITHUB_BRANCH" --force; then
        echo -e "${GREEN}✓ Successfully pushed backups to GitHub${NC}"
    else
        echo -e "${RED}✗ Failed to push to GitHub${NC}"
        echo "Attempting to push with upstream..."
        git push --set-upstream origin "$GITHUB_BRANCH" --force
    fi
fi

echo ""
echo -e "${GREEN}=== Backup Completed Successfully ===${NC}"
echo "Total backups in directory: $(find "$BACKUP_DIR" -name "*.sql.gz" | wc -l)"
echo ""

