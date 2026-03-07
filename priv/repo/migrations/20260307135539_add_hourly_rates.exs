defmodule Jikan.Repo.Migrations.AddHourlyRates do
  use Ecto.Migration

  def change do
    # Add default hourly rate to clients
    alter table(:clients) do
      add :default_hourly_rate, :decimal, precision: 10, scale: 2
    end

    # Add hourly rate to projects
    alter table(:projects) do
      add :hourly_rate, :decimal, precision: 10, scale: 2
    end

    # Add hourly rate override and calculated amount to time entries
    alter table(:time_entries) do
      add :hourly_rate, :decimal, precision: 10, scale: 2
      add :total_amount, :decimal, precision: 10, scale: 2
    end

    # Create indexes for better query performance
    create index(:time_entries, [:billable, :total_amount])
  end
end