#!/bin/bash
set -e

echo "→ Pulling latest code..."
git pull

echo "→ Building Docker image..."
docker build -t ringling/jikan .

echo "→ Stopping old container (if running)..."
docker stop jikan 2>/dev/null || true
docker rm   jikan 2>/dev/null || true

echo "→ Starting new container..."
docker run -d \
  --name jikan \
  -p 4000:4000 \
  -v jikan_data:/app/data \
  --env-file /etc/jikan.env \
  --restart unless-stopped \
  ringling/jikan

echo "→ Running migrations..."
docker exec jikan /app/bin/jikan eval "Jikan.Release.migrate()"

echo "✓ Jikan deployed!"