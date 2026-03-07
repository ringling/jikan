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
EOF
  echo "Please update .env.prod with your actual values"
  exit 1
fi

echo "→ Stopping existing services..."
docker compose --env-file .env.prod down

echo "→ Building and starting services..."
docker compose --env-file .env.prod up -d --build

echo "→ Waiting for database to be ready..."
sleep 10

echo "→ Running migrations..."
docker compose --env-file .env.prod exec app /app/bin/jikan eval "Jikan.Release.migrate()"

# Optional: Run production seeds (only on first deployment)
# Uncomment the following line to seed the database with initial data:
# echo "→ Running production seeds..."
# docker compose --env-file .env.prod exec app /app/bin/jikan eval "Jikan.Release.seed(\"seeds_prod.exs\")"

echo "✓ Jikan deployed with PostgreSQL!"
echo ""
echo "To verify deployment:"
echo "  docker compose --env-file .env.prod logs"
echo "  docker compose --env-file .env.prod ps"
echo ""
echo "To run production seeds manually:"
echo "  docker compose --env-file .env.prod exec app /app/bin/jikan eval 'Jikan.Release.seed(\"seeds_prod.exs\")'"
echo ""
echo "To access PostgreSQL directly:"
echo "  docker compose --env-file .env.prod exec db psql -U postgres -d jikan_prod"