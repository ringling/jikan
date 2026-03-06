# Deploy Jikan to a VPS with Docker

**Stack:** Elixir · Alpine · SQLite · single VPS · git pull workflow

---

## Deploy command

```bash
git pull && \
docker build -t ringling/jikan . && \
docker stop jikan 2>/dev/null; docker rm jikan 2>/dev/null; \
docker run -d \
  --name jikan \
  -p 4000:4000 \
  -v jikan_data:/app/data \
  --env-file /etc/jikan.env \
  --restart unless-stopped \
  ringling/jikan
```

> **Note:** `docker stop jikan` fails on the very first deploy (no container exists yet). The `2>/dev/null` suppresses the error. Use `deploy.sh` in Step 6 for a cleaner approach.

---

## Step 1 — Dockerfile

Multi-stage build: compile in a full Elixir/Alpine image, run from a lean Alpine runtime. SQLite needs `sqlite-dev` in the builder and `sqlite-libs` in runtime.

**Important:** 
- The build stage requires environment variables for compilation. These are set with placeholder values during build and overridden at runtime.
- Node.js is required during build to compile and minify CSS/JS assets
- The `mix assets.deploy` command runs esbuild, tailwind, and phx.digest to prepare static files for production

```dockerfile
# ── Stage 1: Build ─────────────────────────────────────
FROM hexpm/elixir:1.19.5-erlang-28.4-alpine-3.21.6 AS builder

# Install build dependencies including Node.js for asset compilation
RUN apk add --no-cache build-base git sqlite-dev nodejs npm

WORKDIR /app
ENV MIX_ENV=prod

RUN mix local.hex --force && mix local.rebar --force

COPY mix.exs mix.lock ./
RUN mix deps.get --only prod

COPY config/config.exs config/prod.exs config/
RUN mix deps.compile

# Copy and compile assets
COPY assets assets
COPY priv priv
COPY lib lib
COPY config/runtime.exs config/

# Install Node.js dependencies for asset compilation
RUN mix assets.setup

# Set required environment variables for build
# These are placeholders needed for compilation and release generation
ENV DATABASE_PATH=/app/build_db.db
ENV SECRET_KEY_BASE=placeholder_for_build_only
ENV PHX_SERVER=true

# Compile assets for production (CSS/JS minification and digest)
RUN mix assets.deploy

# Compile and create release
RUN mix do compile, release

# ── Stage 2: Runtime ───────────────────────────────────
FROM alpine:3.21.6

RUN apk add --no-cache libstdc++ openssl ncurses-libs sqlite-libs

ENV LANG=en_US.UTF-8 LANGUAGE=en_US:en LC_ALL=en_US.UTF-8

WORKDIR /app
RUN chown nobody /app

# Create the data dir for SQLite — will be overridden by volume
RUN mkdir -p /app/data && chown nobody /app/data

COPY --from=builder --chown=nobody:root /app/_build/prod/rel/jikan ./

USER nobody
ENV HOME=/app

# Set default environment variables (can be overridden at runtime)
ENV DATABASE_PATH=/app/data/jikan.db
ENV PHX_SERVER=true

CMD ["/app/bin/jikan", "start"]
```

---

## Step 2 — SQLite persistence

Containers are ephemeral — without a volume, your database is wiped on every redeploy. The `-v jikan_data:/app/data` flag mounts a named volume that survives restarts and container replacements.

```
jikan_data (Docker named volume on VPS host)  ⟷  /app/data/ (inside container)
```

### Why Build-Time Environment Variables?

The Elixir release process compiles `config/runtime.exs` during the build. Even though these configs are evaluated at runtime, the build process needs valid environment variables to complete successfully. The placeholder values used during build are replaced by real values from `/etc/jikan.env` when the container runs.

### `config/runtime.exs` (key sections)

```elixir
import Config

if System.get_env("PHX_SERVER") do
  config :jikan, JikanWeb.Endpoint, server: true
end

if config_env() == :prod do
  database_path =
    System.get_env("DATABASE_PATH") ||
      raise """
      environment variable DATABASE_PATH is missing.
      For example: /app/data/jikan.db
      """

  config :jikan, Jikan.Repo,
    database: database_path,
    pool_size: String.to_integer(System.get_env("POOL_SIZE") || "5")

  secret_key_base =
    System.get_env("SECRET_KEY_BASE") ||
      raise """
      environment variable SECRET_KEY_BASE is missing.
      You can generate one by calling: mix phx.gen.secret
      """

  host = System.get_env("PHX_HOST") || "example.com"
  port = String.to_integer(System.get_env("PORT") || "4000")

  config :jikan, JikanWeb.Endpoint,
    url: [host: host, port: 443, scheme: "https"],
    http: [ip: {0, 0, 0, 0, 0, 0, 0, 0}, port: port],
    secret_key_base: secret_key_base
end
```

> **Tip:** Create the volume once on your VPS: `docker volume create jikan_data`. It persists across redeploys, reboots, and container removals.

---

## Step 3 — Environment file on the VPS

Store secrets on the VPS — never in git or the Docker image. The `--env-file` flag injects them at runtime.

### `/etc/jikan.env` — on VPS, not in repo

```env
SECRET_KEY_BASE=your_64_char_secret_here
PHX_HOST=yourdomain.com
PORT=4000
DATABASE_PATH=/app/data/jikan.db
```

**Create and lock down the file:**

```bash
sudo vim /etc/jikan.env
sudo chmod 600 /etc/jikan.env
```

**Generate `SECRET_KEY_BASE` on your local machine:**

```bash
mix phx.gen.secret
```

---

## Step 4 — Migrations in a release

Mix tasks don't exist in a compiled release. Add this module so migrations can be run via `eval`:

### `lib/jikan/release.ex`

```elixir
defmodule Jikan.Release do
  @app :jikan

  def migrate do
    load_app()
    for repo <- repos() do
      {:ok, _, _} = Ecto.Migrator.with_repo(repo, &Ecto.Migrator.run(&1, :up, all: true))
    end
  end

  defp repos, do: Application.fetch_env!(@app, :ecto_repos)
  defp load_app, do: Application.load(@app)
end
```

Run migrations after the new container is up:

```bash
docker exec jikan /app/bin/jikan eval "Jikan.Release.migrate()"
```

---

## Step 5 — .dockerignore

```
_build/
deps/
.git/
.elixir_ls/
priv/static/
*.md
.env
.env.*
test/
doc/
*.db
*.db-shm
*.db-wal
```

> **Warning:** The `*.db` lines ensure a local dev SQLite file is never accidentally baked into the image.

---

## Step 6 — deploy.sh

A robust redeploy script that handles the first-run case and runs migrations automatically.

```bash
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
```

**First-time setup:**

```bash
chmod +x deploy.sh
docker volume create jikan_data
./deploy.sh
```

---

## VPS first-time setup

```bash
# Install Docker
curl -fsSL https://get.docker.com | sh

# Clone repo
git clone <your-repo-url>
cd jikan

# Create secrets file
sudo nano /etc/jikan.env

# Create persistent DB volume
docker volume create jikan_data

# First deploy
./deploy.sh
```

---

## Quick reference

| Command | Purpose |
|---|---|
| `./deploy.sh` | Full redeploy |
| `docker logs -f jikan` | Tail logs |
| `docker exec -it jikan sh` | Shell into container |
| `docker exec jikan /app/bin/jikan eval "Jikan.Release.migrate()"` | Run migrations manually |
| `docker images ringling/jikan` | Check image size |
| `docker volume inspect jikan_data` | Inspect DB volume |