# MySQL Database Backup Script

A bash script for Ubuntu that automatically backs up MySQL databases, compresses them to `.gz` format, commits them to GitHub, and maintains backups for a configurable retention period (default: 30 days).

## Features

- ✅ Backup multiple MySQL databases
- ✅ Compress backups using gzip (.gz format)
- ✅ Automatic Git commit and push to GitHub
- ✅ Automatic cleanup of backups older than retention period
- ✅ Date-based organization of backups
- ✅ Environment-based configuration
- ✅ GitHub token authentication support
- ✅ Colorful console output
- ✅ Error handling

## Prerequisites

- Ubuntu/Debian Linux
- MySQL/MariaDB server
- Git
- mysqldump utility
- Bash 4.0 or higher

### Installation

1. **Install required packages:**
```bash
sudo apt-get update
sudo apt-get install mysql-client git gzip -y
```

2. **Clone or download this repository**

3. **Configure the script:**
```bash
cp .env.example .env
nano .env  # or use your favorite editor
```

4. **Update the `.env` file with your settings:**
   - MySQL credentials
   - Database names (comma-separated)
   - GitHub repository URL
   - Git user information
   - (Optional) GitHub Personal Access Token

5. **Make the script executable:**
```bash
chmod +x backup.sh
```

## Configuration

### Environment Variables (.env file)

| Variable | Description | Example |
|----------|-------------|---------|
| `MYSQL_HOST` | MySQL server hostname | `localhost` |
| `MYSQL_PORT` | MySQL server port | `3306` |
| `MYSQL_USER` | MySQL username | `root` |
| `MYSQL_PASSWORD` | MySQL password | `your_password` |
| `DATABASES` | Comma-separated list of databases | `db1,db2,db3` |
| `BACKUP_DIR` | Directory to store backups | `./backups` |
| `BACKUP_RETENTION_DAYS` | Days to keep backups | `30` |
| `GITHUB_REPO_URL` | GitHub repository URL | `https://github.com/user/repo.git` |
| `GITHUB_BRANCH` | Git branch name | `main` |
| `GIT_USER_NAME` | Git commit author name | `Your Name` |
| `GIT_USER_EMAIL` | Git commit author email | `email@example.com` |
| `GITHUB_TOKEN` | (Optional) GitHub Personal Access Token | `ghp_xxxxx` |

### GitHub Authentication

#### Option 1: HTTPS with Personal Access Token (Recommended for automation)

1. Generate a GitHub Personal Access Token:
   - Go to GitHub → Settings → Developer settings → Personal access tokens → Tokens (classic)
   - Click "Generate new token (classic)"
   - Select scopes: `repo` (full control of private repositories)
   - Copy the token

2. Add the token to your `.env` file:
```bash
GITHUB_TOKEN=ghp_your_token_here
```

#### Option 2: SSH

1. Set up SSH keys for GitHub
2. Use SSH URL in `.env`:
```bash
GITHUB_REPO_URL=git@github.com:username/repo.git
```

## Usage

### Manual Backup

Run the script manually:
```bash
./backup.sh
```

### Automated Backups with Cron

Set up a cron job to run backups automatically:

1. **Edit crontab:**
```bash
crontab -e
```

2. **Add a cron job** (examples):

Daily at 2 AM:
```bash
0 2 * * * cd /path/to/db-backup-script && ./backup.sh >> /var/log/mysql-backup.log 2>&1
```

Every 6 hours:
```bash
0 */6 * * * cd /path/to/db-backup-script && ./backup.sh >> /var/log/mysql-backup.log 2>&1
```

Every day at midnight:
```bash
0 0 * * * cd /path/to/db-backup-script && ./backup.sh >> /var/log/mysql-backup.log 2>&1
```

## Backup Structure

Backups are organized by date:

```
backups/
├── 2026-01-01/
│   ├── database1_20260101_020000.sql.gz
│   ├── database2_20260101_020000.sql.gz
├── 2026-01-02/
│   ├── database1_20260102_020000.sql.gz
│   ├── database2_20260102_020000.sql.gz
└── ...
```

## Restoring from Backup

To restore a database from a backup:

```bash
# Decompress and restore
gunzip < backups/2026-01-01/database1_20260101_020000.sql.gz | mysql -u username -p database_name
```

Or in two steps:

```bash
# Decompress
gunzip backups/2026-01-01/database1_20260101_020000.sql.gz

# Restore
mysql -u username -p database_name < backups/2026-01-01/database1_20260101_020000.sql
```

## Troubleshooting

### Permission Denied

Make sure the script is executable:
```bash
chmod +x backup.sh
```

### MySQL Access Denied

- Verify MySQL credentials in `.env`
- Ensure MySQL user has appropriate permissions:
```sql
GRANT SELECT, LOCK TABLES, SHOW VIEW ON database_name.* TO 'user'@'localhost';
FLUSH PRIVILEGES;
```

### Git Push Failed

- Verify GitHub repository URL
- Check GitHub token permissions (if using token)
- Ensure you have write access to the repository

### Old Backups Not Deleted

The script uses the file modification time (`mtime`). If backups aren't deleted:
- Check `BACKUP_RETENTION_DAYS` value
- Verify file permissions in backup directory

## Security Considerations

1. **Never commit `.env` file** - It's already in `.gitignore`
2. **Protect your `.env` file:**
```bash
chmod 600 .env
```
3. **Use GitHub Personal Access Token** with minimal required permissions
4. **Consider encrypting backups** for sensitive data
5. **Use MySQL user with minimal required privileges**

## License

MIT License - Feel free to use and modify as needed.

## Support

For issues or questions, please open an issue in the GitHub repository.

# mysql-backup-manager
