# Production Setup - Jikan Time Tracking

## Production Database Created Successfully ✅

### Admin Credentials
- **Email:** jikan@ringling.info
- **Password:** bGMcemG6dN4nXg/c
- **Role:** admin

⚠️ **IMPORTANT:** Save this password securely and change it after first login.

## Environment Configuration

The production environment has been configured with:
- **Database:** SQLite at `./jikan_prod.db`
- **Secret Key Base:** Generated and stored in `.env.prod`
- **Port:** 4001 (for testing, change as needed)
- **Host:** localhost (change to your domain)

## Files Created

1. **`.env.prod`** - Production environment variables
2. **`priv/repo/seeds_prod.exs`** - Production seeds (admin user only)
3. **`jikan_prod.db`** - Production SQLite database
4. **`priv/static/`** - Compiled and digested assets

## Running in Production

### Quick Start
```bash
source .env.prod
MIX_ENV=prod mix phx.server
```

### Step by Step
1. Load environment variables: `source .env.prod`
2. Create database: `MIX_ENV=prod mix ecto.create`
3. Run migrations: `MIX_ENV=prod mix ecto.migrate`
4. Seed admin user: `MIX_ENV=prod mix run priv/repo/seeds_prod.exs`
5. Start server: `MIX_ENV=prod mix phx.server`

## Deployment Notes

For actual production deployment:

1. **Update `.env.prod`:**
   - Set `PHX_HOST` to your actual domain
   - Change `PORT` if needed
   - Ensure `DATABASE_PATH` points to a persistent location

2. **Security:**
   - Keep `.env.prod` secure and never commit it
   - Use environment variables on your server
   - Consider using PostgreSQL for larger deployments

3. **Running as a Service:**
   ```bash
   # Using systemd (example)
   MIX_ENV=prod elixir --erl "-detached" -S mix phx.server
   ```

4. **With a Release:**
   ```bash
   MIX_ENV=prod mix release
   _build/prod/rel/jikan/bin/jikan start
   ```

## Features Included

- ✅ Timer with pause/resume for lunch breaks
- ✅ Manual pause duration editing
- ✅ Multi-user support with role-based access
- ✅ Client and project management
- ✅ Time entry tracking and reporting
- ✅ European 24-hour time format
- ✅ Japanese kanji branding (時間 Jikan)

## Next Steps

1. Log in with the admin credentials
2. Create clients and projects
3. Start tracking time!
4. Consider setting up regular database backups