defmodule Jikan.Repo do
  use Ecto.Repo,
    otp_app: :jikan,
    adapter: Ecto.Adapters.SQLite3
end
