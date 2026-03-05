defmodule Jikan.Tracking.TimeEntry do
  use Ecto.Schema
  import Ecto.Changeset

  schema "time_entries" do
    field :description, :string
    field :date, :date
    field :start_time, :time
    field :end_time, :time
    field :duration_minutes, :integer
    field :pause_duration_minutes, :integer, default: 0
    field :paused_at, :time
    field :billable, :boolean, default: true
    
    belongs_to :project, Jikan.Tracking.Project
    belongs_to :user, Jikan.Accounts.User

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(time_entry, attrs) do
    time_entry
    |> cast(attrs, [:description, :date, :start_time, :end_time, :duration_minutes, :pause_duration_minutes, :paused_at, :billable, :project_id, :user_id])
    |> validate_required([:date, :duration_minutes, :billable, :project_id, :user_id])
    |> validate_number(:duration_minutes, greater_than_or_equal_to: 0)
    |> validate_number(:pause_duration_minutes, greater_than_or_equal_to: 0)
    |> calculate_duration()
    |> validate_time_order()
    |> foreign_key_constraint(:project_id)
    |> foreign_key_constraint(:user_id)
  end

  defp calculate_duration(changeset) do
    start_time = get_change(changeset, :start_time)
    end_time = get_change(changeset, :end_time)

    if start_time && end_time do
      duration = Time.diff(end_time, start_time, :minute)
      put_change(changeset, :duration_minutes, duration)
    else
      changeset
    end
  end

  defp validate_time_order(changeset) do
    start_time = get_field(changeset, :start_time)
    end_time = get_field(changeset, :end_time)

    if start_time && end_time && Time.compare(start_time, end_time) == :gt do
      add_error(changeset, :end_time, "must be after start time")
    else
      changeset
    end
  end
end
