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
    field :hourly_rate, :decimal
    field :total_amount, :decimal
    
    belongs_to :project, Jikan.Tracking.Project
    belongs_to :user, Jikan.Accounts.User

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(time_entry, attrs) do
    time_entry
    |> cast(attrs, [:description, :date, :start_time, :end_time, :duration_minutes, :pause_duration_minutes, :paused_at, :billable, :hourly_rate, :project_id, :user_id])
    |> validate_required([:date, :duration_minutes, :billable, :project_id, :user_id])
    |> validate_number(:duration_minutes, greater_than_or_equal_to: 0)
    |> validate_number(:pause_duration_minutes, greater_than_or_equal_to: 0)
    |> validate_number(:hourly_rate, greater_than_or_equal_to: 0)
    |> calculate_duration()
    |> validate_time_order()
    |> calculate_total_amount()
    |> foreign_key_constraint(:project_id)
    |> foreign_key_constraint(:user_id)
  end

  defp calculate_duration(changeset) do
    # Check if either time has changed
    start_changed = get_change(changeset, :start_time)
    end_changed = get_change(changeset, :end_time)
    
    # If either time changed, recalculate duration
    if start_changed || end_changed do
      # Get the actual values (from changes or existing data)
      start_time = get_field(changeset, :start_time)
      end_time = get_field(changeset, :end_time)
      
      if start_time && end_time do
        duration = Time.diff(end_time, start_time, :minute)
        put_change(changeset, :duration_minutes, duration)
      else
        changeset
      end
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

  defp calculate_total_amount(changeset) do
    billable = get_field(changeset, :billable)
    hourly_rate = get_field(changeset, :hourly_rate)
    duration_minutes = get_field(changeset, :duration_minutes)
    pause_duration = get_field(changeset, :pause_duration_minutes) || 0

    if billable && hourly_rate && duration_minutes do
      # Calculate net working minutes (total minus pause)
      net_minutes = Kernel.max(0, duration_minutes - pause_duration)
      # Convert to hours and calculate amount
      hours = Decimal.div(Decimal.new(net_minutes), Decimal.new(60))
      total = Decimal.mult(hours, hourly_rate)
      # Round to 2 decimal places
      rounded_total = Decimal.round(total, 2)
      put_change(changeset, :total_amount, rounded_total)
    else
      # Set to 0 if not billable or no rate
      if billable == false do
        put_change(changeset, :total_amount, Decimal.new(0))
      else
        changeset
      end
    end
  end
end
