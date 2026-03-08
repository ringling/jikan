# Jikan - Time Tracking Application

Jikan is a full-stack time tracking web application built with Elixir, Phoenix LiveView, and PostgreSQL. It allows users to log work hours against projects and clients, track billable time, and manage hourly rates with real-time UI updates.

## Key Features

- **Time Tracking**: Log time with start/end times or manual duration entry
- **Pause Duration**: Track breaks and pauses (lunch, meetings) that don't count toward billable time
- **Hourly Rates**: Hierarchical rate system (entry → project → client default)
- **Automatic Billing**: Calculate amounts based on net working time and hourly rates
- **Dashboard**: View daily, weekly, and monthly summaries with revenue tracking
- **CSV Export**: Export time entries with flexible filtering options
- **Role-Based Access**: Employee, Manager, and Admin roles with different permissions
- **Real-Time Updates**: LiveView-powered interface with no JavaScript required
- **Docker Deployment**: Production-ready Docker Compose setup with PostgreSQL

## Quick Start - Development

### Prerequisites
- Elixir 1.16+
- PostgreSQL 14+
- Node.js 18+ (for assets)

### Setup

```bash
# Install dependencies
mix setup

# Start PostgreSQL (if using Docker)
docker run --name postgres-dev -e POSTGRES_PASSWORD=postgres -p 5432:5432 -d postgres:15-alpine

# Run migrations
mix ecto.migrate

# Seed development data
mix run priv/repo/seeds.exs

# Start Phoenix server
mix phx.server
```

Now visit [`localhost:4000`](http://localhost:4000)

### Development Accounts

After running seeds:
- Admin: `admin@example.com` / `password123456`
- Manager: `manager@example.com` / `password123456`  
- Employee: `demo@example.com` / `password123456`

## Production Deployment

### Using Docker Compose

1. Clone the repository on your server
2. Create `.env.prod` file:
```bash
SECRET_KEY_BASE=your-secret-key-here
PHX_HOST=your-domain.com
```

3. Run deployment:
```bash
./deploy.sh
```

### Docker Commands

```bash
# View logs
docker compose --env-file .env.prod logs

# Access IEx console
docker exec -it jikan-app-1 /app/bin/jikan remote

# Run production seeds
docker compose --env-file .env.prod exec app /app/bin/jikan eval 'Jikan.Release.seed("seeds_prod.exs")'

# Access PostgreSQL
docker compose --env-file .env.prod exec db psql -U postgres -d jikan_prod
```

## Documentation

- [Architecture Overview](docs/ARCHITECTURE.md) - System design and technical details
- [Features Guide](docs/FEATURES.md) - Complete feature documentation
- [Production Setup](docs/PRODUCTION_SETUP.md) - Detailed deployment instructions
- [Docker Deployment](docs/DOCKER_DEPLOY.md) - Container configuration

## Technology Stack

- **Backend**: Elixir with Phoenix Framework
- **Frontend**: Phoenix LiveView (server-rendered reactive UI)
- **Database**: PostgreSQL
- **Styling**: Tailwind CSS + DaisyUI components
- **Deployment**: Docker Compose
- **Authentication**: Phoenix built-in authentication

## Project Structure

```
lib/
├── jikan/          # Business logic
│   ├── accounts/   # User management and authentication
│   ├── tracking/   # Time entries, projects, clients
│   └── release.ex  # Production release tasks
├── jikan_web/      # Web interface
│   ├── live/       # LiveView modules
│   └── components/ # Reusable UI components
```

## Learn More

- **Phoenix**: https://www.phoenixframework.org/
- **LiveView**: https://hexdocs.pm/phoenix_live_view/
- **Elixir**: https://elixir-lang.org/
- **DaisyUI**: https://daisyui.com/

## License

Private project - All rights reserved