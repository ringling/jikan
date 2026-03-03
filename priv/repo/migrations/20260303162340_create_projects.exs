defmodule Jikan.Repo.Migrations.CreateProjects do
  use Ecto.Migration

  def change do
    create table(:projects) do
      add :name, :string, null: false
      add :description, :string
      add :color, :string, default: "#3B82F6", null: false
      add :archived, :boolean, default: false, null: false
      add :client_id, references(:clients, on_delete: :delete_all), null: false
      add :user_id, references(:users, on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime)
    end

    create index(:projects, [:client_id])
    create index(:projects, [:user_id])
    create index(:projects, [:archived])
  end
end
