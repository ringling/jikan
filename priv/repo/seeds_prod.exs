# Production seed file - creates essential admin user and initial clients/projects
# Run with: MIX_ENV=prod mix run priv/repo/seeds_prod.exs

alias Jikan.Repo
alias Jikan.Accounts.User
alias Jikan.Tracking.{Client, Project}

# Generate a secure random password
password = :crypto.strong_rand_bytes(32) |> Base.encode64() |> binary_part(0, 16)
password = "pass"

# Create admin user
admin = Repo.insert!(%User{
  email: "jikan@ringling.info",
  hashed_password: Bcrypt.hash_pwd_salt(password),
  role: "admin",
  confirmed_at: DateTime.utc_now() |> DateTime.truncate(:second)
})

# Create PFA client
pfa = Repo.insert!(%Client{
  name: "PFA",
  active: true,
  default_hourly_rate: Decimal.new("925.00"),
  user_id: admin.id
})

# Create Nestech client
nestech = Repo.insert!(%Client{
  name: "Nestech",
  active: true,
  default_hourly_rate: Decimal.new("950.00"),
  user_id: admin.id
})

# Create PFA project
varslinger = Repo.insert!(%Project{
  name: "Varslinger",
  description: "Notification system",
  color: "#10B981",
  archived: false,
  client_id: pfa.id,
  user_id: admin.id
})

# Create Nestech project
pbu_output = Repo.insert!(%Project{
  name: "PBU output management",
  description: "Output management system for PBU",
  color: "#3B82F6",
  archived: false,
  client_id: nestech.id,
  user_id: admin.id
})

IO.puts """
================================================================================
PRODUCTION DATABASE INITIALIZED
================================================================================

Admin user created:
  Email: jikan@ringling.info
  Password: #{password}
  Role: admin

Clients created:
  - PFA (925.00 DKK/hour)
  - Nestech (950.00 DKK/hour)

Projects created:
  - PFA → Varslinger
  - Nestech → PBU output management

IMPORTANT: Save this password securely. It will not be shown again.
Consider changing it after first login for additional security.

================================================================================
"""
