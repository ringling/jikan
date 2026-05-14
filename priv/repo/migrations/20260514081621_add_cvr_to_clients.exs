defmodule Jikan.Repo.Migrations.AddCvrToClients do
  use Ecto.Migration

  def change do
    alter table(:clients) do
      add :cvr, :string
    end
  end
end
