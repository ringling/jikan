defmodule Jikan.Repo.Migrations.AddAddressToClients do
  use Ecto.Migration

  def change do
    alter table(:clients) do
      add :address, :text
    end
  end
end
