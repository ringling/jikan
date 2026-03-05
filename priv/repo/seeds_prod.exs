# Production seed file - creates only essential admin user
# Run with: MIX_ENV=prod mix run priv/repo/seeds_prod.exs

alias Jikan.Repo
alias Jikan.Accounts.User

# Generate a secure random password
password = :crypto.strong_rand_bytes(32) |> Base.encode64() |> binary_part(0, 16)

# Create admin user
admin = Repo.insert!(%User{
  email: "jikan@ringling.info",
  hashed_password: Bcrypt.hash_pwd_salt(password),
  role: "admin",
  confirmed_at: DateTime.utc_now() |> DateTime.truncate(:second)
})

IO.puts """
================================================================================
PRODUCTION DATABASE INITIALIZED
================================================================================

Admin user created:
  Email: jikan@ringling.info
  Password: #{password}
  Role: admin

IMPORTANT: Save this password securely. It will not be shown again.
Consider changing it after first login for additional security.

================================================================================
"""