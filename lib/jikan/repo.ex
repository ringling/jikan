defmodule Jikan.Repo do
  use Ecto.Repo,
    otp_app: :jikan,
    adapter: Ecto.Adapters.Postgres
end
