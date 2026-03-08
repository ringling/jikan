# Database Backup and Restore Guide

## Overview

This guide covers PostgreSQL backup strategies for the Jikan application running in Docker. All backups should be performed regularly and tested to ensure data recovery capability.

## Manual Backup Methods

### 1. Standard SQL Dump

Create a plain-text SQL backup that can be restored using `psql`:

```bash
# Basic backup
docker compose --env-file .env.prod exec db pg_dump -U postgres jikan_prod > backup_$(date +%Y%m%d).sql

# With timestamp in filename
docker compose --env-file .env.prod exec db pg_dump -U postgres jikan_prod > jikan_backup_$(date +%Y%m%d_%H%M%S).sql
```

### 2. Compressed Backups

Reduce backup file size with compression:

```bash
# Gzip compression
docker compose --env-file .env.prod exec db pg_dump -U postgres jikan_prod | gzip > backup_$(date +%Y%m%d).sql.gz

# Bzip2 compression (better compression, slower)
docker compose --env-file .env.prod exec db pg_dump -U postgres jikan_prod | bzip2 > backup_$(date +%Y%m%d).sql.bz2
```

### 3. Custom Format Dumps

PostgreSQL's custom format provides better performance and flexibility:

```bash
# Custom format (recommended for large databases)
docker compose --env-file .env.prod exec db pg_dump -U postgres -Fc jikan_prod > backup_$(date +%Y%m%d).dump

# With compression level (0-9, default is 6)
docker compose --env-file .env.prod exec db pg_dump -U postgres -Fc -Z 9 jikan_prod > backup_$(date +%Y%m%d).dump
```

### 4. Docker Volume Backup

Backup the entire PostgreSQL data directory:

```bash
# Stop the database container first (optional but safer)
docker compose --env-file .env.prod stop db

# Backup volume
docker run --rm -v jikan_data:/data -v $(pwd):/backup alpine tar -czf /backup/data_backup_$(date +%Y%m%d).tar.gz -C /data .

# Restart database
docker compose --env-file .env.prod start db
```

## Automated Backups

### Create Backup Script

Create `/opt/jikan/backup.sh`:

```bash
#!/bin/bash

# Configuration
BACKUP_DIR="/opt/jikan/backups"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
KEEP_DAYS=7
DB_NAME="jikan_prod"
DB_USER="postgres"

# Create backup directory if it doesn't exist
mkdir -p $BACKUP_DIR

# Log function
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

log "Starting database backup..."

# Create backup
if docker compose --env-file /opt/jikan/.env.prod exec -T db \
    pg_dump -U $DB_USER $DB_NAME > "$BACKUP_DIR/jikan_$TIMESTAMP.sql"; then
    
    log "Backup created successfully: jikan_$TIMESTAMP.sql"
    
    # Compress the backup
    gzip "$BACKUP_DIR/jikan_$TIMESTAMP.sql"
    log "Backup compressed: jikan_$TIMESTAMP.sql.gz"
    
    # Calculate backup size
    SIZE=$(du -h "$BACKUP_DIR/jikan_$TIMESTAMP.sql.gz" | cut -f1)
    log "Backup size: $SIZE"
    
    # Remove old backups
    find $BACKUP_DIR -name "jikan_*.sql.gz" -mtime +$KEEP_DAYS -delete
    log "Old backups cleaned up (keeping last $KEEP_DAYS days)"
    
else
    log "ERROR: Backup failed!"
    exit 1
fi

log "Backup process completed"
```

Make it executable:
```bash
chmod +x /opt/jikan/backup.sh
```

### Schedule with Cron

```bash
# Edit crontab
crontab -e

# Add daily backup at 2 AM
0 2 * * * /opt/jikan/backup.sh >> /opt/jikan/backups/backup.log 2>&1

# Or multiple times per day (2 AM, 2 PM)
0 2,14 * * * /opt/jikan/backup.sh >> /opt/jikan/backups/backup.log 2>&1
```

## Copy Backups to Local Machine

### Using SCP from Local Machine

Download backups from production server to your local machine:

```bash
# Download single backup file
scp user@your-server:/opt/jikan/backups/jikan_20240308.sql.gz ~/backups/

# Download today's backup
scp user@your-server:/opt/jikan/backups/jikan_$(date +%Y%m%d)*.sql.gz ~/backups/

# Download all backups from March 2024
scp user@your-server:/opt/jikan/backups/jikan_202403*.sql.gz ~/backups/

# Download entire backups directory
scp -r user@your-server:/opt/jikan/backups ~/jikan-backups/

# With specific SSH port
scp -P 2222 user@your-server:/opt/jikan/backups/latest.sql.gz ~/backups/

# Using SSH key
scp -i ~/.ssh/id_rsa user@your-server:/opt/jikan/backups/*.sql.gz ~/backups/
```

### Create Local Backup Directory Structure

Organize backups on your local machine:

```bash
# Create organized backup structure
mkdir -p ~/jikan-backups/{daily,weekly,monthly}

# Download and organize
scp user@server:/opt/jikan/backups/jikan_$(date +%Y%m%d)*.sql.gz ~/jikan-backups/daily/
```

### Automated Local Backup Script

Create `~/scripts/download_jikan_backup.sh`:

```bash
#!/bin/bash

# Configuration
REMOTE_USER="user"
REMOTE_HOST="your-server.com"
REMOTE_DIR="/opt/jikan/backups"
LOCAL_DIR="$HOME/jikan-backups"
SSH_KEY="$HOME/.ssh/id_rsa"

# Create local directory
mkdir -p "$LOCAL_DIR/$(date +%Y/%m)"

# Download today's backup
echo "Downloading backup from $REMOTE_HOST..."
scp -i "$SSH_KEY" \
    "$REMOTE_USER@$REMOTE_HOST:$REMOTE_DIR/jikan_$(date +%Y%m%d)*.sql.gz" \
    "$LOCAL_DIR/$(date +%Y/%m)/"

# Verify download
if [ $? -eq 0 ]; then
    echo "✓ Backup downloaded successfully to $LOCAL_DIR/$(date +%Y/%m)/"
    ls -lh "$LOCAL_DIR/$(date +%Y/%m)/"*.sql.gz
else
    echo "✗ Download failed!"
    exit 1
fi
```

### Direct Backup to Local Machine

Create backup on server and pipe directly to local machine:

```bash
# Direct backup without storing on server
ssh user@your-server "docker compose --env-file /opt/jikan/.env.prod exec db pg_dump -U postgres jikan_prod" | gzip > ~/backups/jikan_$(date +%Y%m%d).sql.gz

# With progress indicator
ssh user@your-server "docker compose --env-file /opt/jikan/.env.prod exec db pg_dump -U postgres jikan_prod" | pv | gzip > ~/backups/jikan_$(date +%Y%m%d).sql.gz
```

## Remote Backup to Another Server

### Direct SSH Backup

```bash
# Backup directly to remote backup server
docker compose --env-file .env.prod exec db pg_dump -U postgres jikan_prod | \
    ssh backup@backup-server "cat > /backups/jikan_$(date +%Y%m%d).sql"

# With compression
docker compose --env-file .env.prod exec db pg_dump -U postgres jikan_prod | \
    gzip | ssh backup@backup-server "cat > /backups/jikan_$(date +%Y%m%d).sql.gz"
```

### Rsync for Incremental Backups

```bash
# Sync backups directory to remote server
rsync -avz --delete /opt/jikan/backups/ backup@backup-server:/backups/jikan/

# With bandwidth limit (in KB/s)
rsync -avz --bwlimit=1000 /opt/jikan/backups/ backup@backup-server:/backups/jikan/
```

## Restore Procedures

### From SQL Dump

```bash
# Standard SQL dump
docker compose --env-file .env.prod exec -T db psql -U postgres jikan_prod < backup.sql

# Compressed SQL dump
gunzip -c backup.sql.gz | docker compose --env-file .env.prod exec -T db psql -U postgres jikan_prod

# Drop and recreate database first (clean restore)
docker compose --env-file .env.prod exec db psql -U postgres -c "DROP DATABASE IF EXISTS jikan_prod"
docker compose --env-file .env.prod exec db psql -U postgres -c "CREATE DATABASE jikan_prod"
docker compose --env-file .env.prod exec -T db psql -U postgres jikan_prod < backup.sql
```

### From Custom Format

```bash
# Restore custom format dump
docker compose --env-file .env.prod exec -T db pg_restore -U postgres -d jikan_prod < backup.dump

# With clean option (drop objects before recreating)
docker compose --env-file .env.prod exec -T db pg_restore -U postgres -c -d jikan_prod < backup.dump

# Restore to new database
docker compose --env-file .env.prod exec db createdb -U postgres jikan_test
docker compose --env-file .env.prod exec -T db pg_restore -U postgres -d jikan_test < backup.dump
```

### From Docker Volume Backup

```bash
# Stop containers
docker compose --env-file .env.prod down

# Restore volume
docker run --rm -v jikan_data:/data -v $(pwd):/backup alpine tar -xzf /backup/data_backup.tar.gz -C /data

# Start containers
docker compose --env-file .env.prod up -d
```

### Restore to Local Development

```bash
# Download backup from production
scp user@server:/opt/jikan/backups/latest.sql.gz ~/Downloads/

# Extract
gunzip ~/Downloads/latest.sql.gz

# Restore to local PostgreSQL
psql -U postgres -c "DROP DATABASE IF EXISTS jikan_dev"
psql -U postgres -c "CREATE DATABASE jikan_dev"
psql -U postgres jikan_dev < ~/Downloads/latest.sql

# Or with Docker
docker exec -i postgres-dev psql -U postgres jikan_dev < ~/Downloads/latest.sql
```

## Backup Verification

### Test Restore Process

```bash
# Create test database
docker compose --env-file .env.prod exec db createdb -U postgres jikan_test

# Restore backup to test database
docker compose --env-file .env.prod exec -T db psql -U postgres jikan_test < backup.sql

# Verify restoration
docker compose --env-file .env.prod exec db psql -U postgres -d jikan_test -c "SELECT COUNT(*) FROM time_entries;"

# Clean up test database
docker compose --env-file .env.prod exec db dropdb -U postgres jikan_test
```

### Check Backup Integrity

```bash
# Check SQL dump syntax
docker compose --env-file .env.prod exec -T db psql -U postgres -f backup.sql --dry-run

# List contents of custom format dump
pg_restore -l backup.dump

# Verify compressed file
gzip -t backup.sql.gz && echo "✓ File is valid" || echo "✗ File is corrupted"
```

## Best Practices

### Security
- Store backups encrypted: `gpg -c backup.sql`
- Use SSH keys instead of passwords for SCP
- Restrict backup directory permissions: `chmod 700 /opt/jikan/backups`
- Never commit backups to version control

### Retention Policy
- Daily backups: Keep for 7 days
- Weekly backups: Keep for 4 weeks  
- Monthly backups: Keep for 6 months
- Yearly backups: Keep indefinitely

### Testing
- Test restore process monthly
- Verify backup integrity after creation
- Document restore time for planning
- Keep restore procedures updated

### Monitoring
- Check backup script logs daily
- Set up alerts for failed backups
- Monitor backup sizes for anomalies
- Track backup/restore times

### Storage
- Keep backups in multiple locations
- Use different storage media (local, cloud, remote)
- Implement 3-2-1 rule: 3 copies, 2 different media, 1 offsite

## Troubleshooting

### Common Issues

**Permission denied:**
```bash
# Ensure proper permissions
sudo chown -R $USER:$USER /opt/jikan/backups
chmod 755 /opt/jikan/backups
```

**Disk space issues:**
```bash
# Check available space
df -h /opt/jikan/backups

# Clean old backups manually
find /opt/jikan/backups -name "*.sql.gz" -mtime +30 -delete
```

**Connection refused:**
```bash
# Check if database is running
docker compose --env-file .env.prod ps db

# Check database logs
docker compose --env-file .env.prod logs db
```

**Slow backups:**
```bash
# Use parallel dump for large databases
docker compose --env-file .env.prod exec db pg_dump -U postgres -j 4 -Fd -f /tmp/backup jikan_prod

# Copy directory out
docker cp jikan-db-1:/tmp/backup ./backup_dir
```

## Emergency Recovery

If production database is corrupted:

1. Stop application: `docker compose --env-file .env.prod stop app`
2. Create emergency backup of corrupted data: `docker compose --env-file .env.prod exec db pg_dump -U postgres jikan_prod > corrupted_backup.sql`
3. Stop database: `docker compose --env-file .env.prod stop db`
4. Remove volume: `docker volume rm jikan_data`
5. Start database: `docker compose --env-file .env.prod up -d db`
6. Wait for initialization: `sleep 10`
7. Restore from last known good backup
8. Start application: `docker compose --env-file .env.prod up -d app`
9. Verify functionality
10. Investigate corruption cause