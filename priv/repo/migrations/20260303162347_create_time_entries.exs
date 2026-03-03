defmodule Jikan.Repo.Migrations.CreateTimeEntries do
  use Ecto.Migration

  def change do
    create table(:time_entries) do
      add :description, :string
      add :date, :date, null: false
      add :start_time, :time
      add :end_time, :time
      add :duration_minutes, :integer, null: false
      add :billable, :boolean, default: true, null: false
      add :project_id, references(:projects, on_delete: :delete_all), null: false
      add :user_id, references(:users, on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime)
    end

    create index(:time_entries, [:project_id])
    create index(:time_entries, [:user_id])
    create index(:time_entries, [:date])
    create index(:time_entries, [:billable])
  end
end
