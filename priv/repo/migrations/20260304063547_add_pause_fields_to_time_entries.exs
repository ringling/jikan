defmodule Jikan.Repo.Migrations.AddPauseFieldsToTimeEntries do
  use Ecto.Migration

  def change do
    alter table(:time_entries) do
      add :pause_duration_minutes, :integer, default: 0, null: false
      add :paused_at, :time
    end
  end
end
