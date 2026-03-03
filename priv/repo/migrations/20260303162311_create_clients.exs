defmodule Jikan.Repo.Migrations.CreateClients do
  use Ecto.Migration

  def change do
    create table(:clients) do
      add :name, :string, null: false
      add :contact_email, :string
      add :active, :boolean, default: true, null: false
      add :user_id, references(:users, on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime)
    end

    create index(:clients, [:user_id])
    create unique_index(:clients, [:name, :user_id])
  end
end
