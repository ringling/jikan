# Production Setup Guide

## Prerequisites

- Ubuntu/Debian server (or similar Linux distribution)
- Docker and Docker Compose installed
- Domain name pointed to your server
- SSL certificate (optional, recommended for production)

## Initial Server Setup

### 1. Install Docker

```bash
# Update system packages
sudo apt update && sudo apt upgrade -y

# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

# Add your user to docker group
sudo usermod -aG docker $USER

# Log out and back in for group changes to take effect
```

### 2. Install Docker Compose

```bash
# Download Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose

# Make it executable
sudo chmod +x /usr/local/bin/docker-compose

# Verify installation
docker-compose --version
```

Note: Modern Docker includes `docker compose` as a plugin, so you can use `docker compose` instead of `docker-compose`.

## Application Deployment

### 1. Clone Repository

```bash
cd /opt
sudo git clone https://github.com/ringling/jikan.git
cd jikan
sudo chown -R $USER:$USER .
```

### 2. Configure Environment

Create `.env.prod` file with your production settings:

```bash
# Generate a secret key
mix phx.gen.secret  # Run this locally or use any secure random string generator

# Create .env.prod
cat > .env.prod << EOF
SECRET_KEY_BASE=your-generated-secret-key-here
PHX_HOST=jikan.yourdomain.com
DATABASE_URL=ecto://postgres:postgres@db/jikan_prod
EOF
```

### 3. Deploy Application

```bash
# Run the deployment script
./deploy.sh
```

The deployment script will:
- Pull latest code from repository
- Build Docker images
- Start PostgreSQL and application containers
- Run database migrations
- Show deployment status

### 4. Initial Database Setup

For first-time deployment, seed the production database:

```bash
# Run production seeds
docker compose --env-file .env.prod exec app /app/bin/jikan eval 'Jikan.Release.seed("seeds_prod.exs")'
```

This creates:
- Admin user: `jikan@ringling.info` (password: "pass" - **change immediately!**)
- PFA client (925 DKK/hour) with Varslinger project
- Nestech client (950 DKK/hour) with PBU output management project

**Important**: Change the admin password after first login!

## SSL Setup with Nginx Proxy Manager

For SSL certificates and reverse proxy, you can use Nginx Proxy Manager or configure Nginx directly.

### Using Nginx Proxy Manager

1. Set up NPM on your server
2. Add proxy host pointing to `http://your-server-ip:4000`
3. Enable WebSocket support
4. Request Let's Encrypt certificate

### Manual Nginx Configuration

Create `/etc/nginx/sites-available/jikan`:

```nginx
upstream phoenix {
    server 127.0.0.1:4000 max_fails=5 fail_timeout=60s;
}

server {
    server_name jikan.yourdomain.com;
    listen 80;

    location / {
        proxy_http_version 1.1;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header Host $host;
        proxy_set_header X-Forwarded-Proto $scheme;
        
        # WebSocket headers
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        
        proxy_pass http://phoenix;
    }
}
```

Enable and secure with SSL:

```bash
# Enable site
sudo ln -s /etc/nginx/sites-available/jikan /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl reload nginx

# Get SSL certificate
sudo certbot --nginx -d jikan.yourdomain.com
```

## Management Commands

### View Logs

```bash
# All containers
docker compose --env-file .env.prod logs

# Application only
docker compose --env-file .env.prod logs app

# Follow logs in real-time
docker compose --env-file .env.prod logs -f
```

### Access IEx Console

```bash
# Connect to running application
docker exec -it jikan-app-1 /app/bin/jikan remote
```

### Database Access

```bash
# PostgreSQL console
docker compose --env-file .env.prod exec db psql -U postgres -d jikan_prod

# Backup database
docker compose --env-file .env.prod exec db pg_dump -U postgres jikan_prod > backup_$(date +%Y%m%d).sql

# Restore database
docker compose --env-file .env.prod exec -T db psql -U postgres jikan_prod < backup.sql

# Backup Docker volume directly
docker run --rm -v jikan_data:/data -v $(pwd):/backup alpine tar -czf /backup/data_backup_$(date +%Y%m%d).tar.gz -C /data .
```

### Update Application

```bash
# Pull latest changes and redeploy
cd /opt/jikan
git pull
./deploy.sh
```

### Stop/Start Services

```bash
# Stop all services
docker compose --env-file .env.prod down

# Start services
docker compose --env-file .env.prod up -d

# Restart services
docker compose --env-file .env.prod restart
```

## Monitoring

### Health Checks

```bash
# Check container health
docker compose --env-file .env.prod ps

# Detailed health status
docker inspect jikan-app-1 --format='{{json .State.Health}}'
```

### Resource Usage

```bash
# Container resource usage
docker stats

# Disk usage
docker system df
```

## Troubleshooting

### Container Won't Start

1. Check logs: `docker compose --env-file .env.prod logs app`
2. Verify environment variables in `.env.prod`
3. Check disk space: `df -h`
4. Verify PostgreSQL is running: `docker compose --env-file .env.prod ps db`

### Database Connection Issues

1. Verify DATABASE_URL in `.env.prod`
2. Check if database container is healthy
3. Try restarting: `docker compose --env-file .env.prod restart`

### WebSocket Connection Issues

If LiveView websockets aren't working:

1. Verify Nginx configuration includes WebSocket headers
2. Check PHX_HOST matches your domain
3. Ensure `check_origin` in endpoint.ex matches your domain
4. Verify firewall allows WebSocket connections

### Cleanup Old Resources

```bash
# Remove unused containers
docker container prune

# Remove unused images
docker image prune

# Remove all unused resources (careful!)
docker system prune -a
```

## Backup Strategy

### Automated Backups

Create `/opt/jikan/backup.sh`:

```bash
#!/bin/bash
BACKUP_DIR="/opt/jikan/backups"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
mkdir -p $BACKUP_DIR

# Backup database
docker compose --env-file /opt/jikan/.env.prod exec -T db \
  pg_dump -U postgres jikan_prod > "$BACKUP_DIR/jikan_$TIMESTAMP.sql"

# Keep only last 7 days of backups
find $BACKUP_DIR -name "jikan_*.sql" -mtime +7 -delete
```

Add to crontab:
```bash
# Daily backup at 2 AM
0 2 * * * /opt/jikan/backup.sh
```

## Features Included

- ✅ Timer with pause/resume for lunch breaks
- ✅ Net duration calculation (total minus pauses)
- ✅ Hourly rates hierarchy (entry → project → client)
- ✅ Multi-user support with role-based access
- ✅ Client and project management
- ✅ Time entry tracking and reporting
- ✅ CSV export with filtering
- ✅ Dashboard with daily/weekly/monthly summaries
- ✅ European 24-hour time format
- ✅ DaisyUI themed interface
- ✅ PostgreSQL database
- ✅ Docker deployment

## Security Considerations

1. **Never commit `.env.prod`** to version control
2. Use strong SECRET_KEY_BASE (at least 64 characters)
3. Change default admin password immediately
4. Regularly update Docker images
5. Set up firewall rules (ufw or iptables)
6. Enable automatic security updates
7. Monitor logs for suspicious activity
8. Use SSL/TLS for all production traffic
9. Regularly backup your database