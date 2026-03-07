#!/bin/bash
set -e

echo "→ Pulling latest code..."
git pull

echo "→ Checking for .env.prod file..."
if [ ! -f ".env.prod" ]; then
  echo "Warning: .env.prod file not found. Creating template..."
  cat > .env.prod << EOF
SECRET_KEY_BASE=your-secret-key-base-here
PHX_HOST=jikan.ringling.info
DATABASE_URL=postgres://username:password@host:5432/database
EOF
  echo "Please update .env.prod with your actual values including external PostgreSQL DATABASE_URL"
  exit 1
fi

echo "→ Stopping existing services..."
docker compose -f docker-compose.simple.yml --env-file .env.prod down || true

echo "→ Cleaning up Docker resources to free space..."
docker system prune -f
docker volume prune -f

echo "→ Building and starting application..."
docker compose -f docker-compose.simple.yml --env-file .env.prod up -d --build

echo "→ Waiting for application to be ready..."
sleep 5

echo "→ Running migrations..."
docker compose -f docker-compose.simple.yml --env-file .env.prod exec app /app/bin/jikan eval "Jikan.Release.migrate()"

# Optional: Run production seeds (only on first deployment)
# Uncomment the following line to seed the database with initial data:
# echo "→ Running production seeds..."
# docker compose -f docker-compose.simple.yml --env-file .env.prod exec app /app/bin/jikan eval "Jikan.Release.seed(\"seeds_prod.exs\")"

echo "✓ Jikan deployed with external PostgreSQL!"
echo ""
echo "To verify deployment:"
echo "  docker compose -f docker-compose.simple.yml --env-file .env.prod logs"
echo "  docker compose -f docker-compose.simple.yml --env-file .env.prod ps"
echo ""
echo "To run production seeds manually:"
echo "  docker compose -f docker-compose.simple.yml --env-file .env.prod exec app /app/bin/jikan eval 'Jikan.Release.seed(\"seeds_prod.exs\")'"