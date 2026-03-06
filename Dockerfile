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
ENV DATABASE_PATH=/app/build_db.db
ENV SECRET_KEY_BASE=placeholder_for_build
ENV PHX_SERVER=true

# Compile assets for production
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