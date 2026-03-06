#!/bin/bash
set -e

echo "→ Pulling latest code..."
git pull

echo "→ Building Docker image..."
docker build -t ringling/jikan .

echo "→ Checking Docker volume..."
if ! docker volume ls | grep -q "jikan_data"; then
  echo "→ Creating Docker volume for database..."
  docker volume create jikan_data
else
  echo "→ Using existing jikan_data volume"
fi

echo "→ Stopping old container (if running)..."
docker stop --timeout jikan 2>/dev/null || true
docker rm   jikan 2>/dev/null || true

echo "→ Starting new container..."
docker run -d \
  --name jikan \
  -p 4000:4000 \
  -v jikan_data:/app/data \
  --env-file /etc/jikan.env \
  --restart unless-stopped \
  ringling/jikan

echo "→ Waiting for container to be ready..."
sleep 3

echo "→ Running migrations..."
docker exec jikan /app/bin/jikan eval "Jikan.Release.migrate()"

# Optional: Run production seeds (only on first deployment)
# Uncomment the following line to seed the database with initial data:
# echo "→ Running production seeds..."
# docker exec jikan /app/bin/jikan eval "Jikan.Release.seed(\"seeds_prod.exs\")"

echo "→ Verifying volume mount..."
docker exec jikan ls -la /app/data/ || echo "Warning: Could not verify data directory"

echo "✓ Jikan deployed!"
echo ""
echo "To verify deployment:"
echo "  docker logs jikan"
echo "  docker exec jikan ls -la /app/data/"
echo "  docker volume inspect jikan_data"
echo ""
echo "To run production seeds manually:"
echo "  docker exec jikan /app/bin/jikan eval 'Jikan.Release.seed(\"seeds_prod.exs\")'"