defmodule Jikan.Tracking do
  @moduledoc """
  The Tracking context.
  """

  import Ecto.Query, warn: false
  alias Jikan.Repo
  alias Jikan.Tracking.{Client, Project, TimeEntry}

  # ===== CLIENT FUNCTIONS =====

  @doc """
  Returns the list of clients for a user.
  """
  def list_clients(user) do
    Client
    |> where(user_id: ^user.id)
    |> order_by(asc: :name)
    |> preload(:projects)
    |> Repo.all()
  end

  @doc """
  Gets a single client for a user.

  Raises `Ecto.NoResultsError` if the Client does not exist or belongs to another user.
  """
  def get_client!(user, id) do
    Client
    |> where(user_id: ^user.id, id: ^id)
    |> preload(:projects)
    |> Repo.one!()
  end

  @doc """
  Creates a client for a user.
  """
  def create_client(user, attrs) do
    attrs = Map.put(attrs, "user_id", user.id)
    
    %Client{}
    |> Client.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a client.
  """
  def update_client(%Client{} = client, attrs) do
    client
    |> Client.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a client.
  """
  def delete_client(%Client{} = client) do
    Repo.delete(client)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking client changes.
  """
  def change_client(%Client{} = client, attrs \\ %{}) do
    Client.changeset(client, attrs)
  end

  # ===== PROJECT FUNCTIONS =====

  @doc """
  Returns the list of projects for a user.
  """
  def list_projects(user, opts \\ []) do
    archived = Keyword.get(opts, :archived, false)
    
    Project
    |> where(user_id: ^user.id, archived: ^archived)
    |> order_by(asc: :name)
    |> preload(:client)
    |> Repo.all()
  end

  @doc """
  Gets a single project for a user.

  Raises `Ecto.NoResultsError` if the Project does not exist or belongs to another user.
  """
  def get_project!(user, id) do
    Project
    |> where(user_id: ^user.id, id: ^id)
    |> preload(:client)
    |> Repo.one!()
  end

  @doc """
  Creates a project for a user.
  """
  def create_project(user, attrs) do
    attrs = Map.put(attrs, "user_id", user.id)
    
    %Project{}
    |> Project.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a project.
  """
  def update_project(%Project{} = project, attrs) do
    project
    |> Project.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a project.
  """
  def delete_project(%Project{} = project) do
    Repo.delete(project)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking project changes.
  """
  def change_project(%Project{} = project, attrs \\ %{}) do
    Project.changeset(project, attrs)
  end

  @doc """
  Archives or unarchives a project.
  """
  def archive_project(%Project{} = project, archived \\ true) do
    update_project(project, %{"archived" => archived})
  end

  # ===== TIME ENTRY FUNCTIONS =====

  @doc """
  Returns the list of time entries for a user with optional filters.
  """
  def list_time_entries(user, filters \\ %{}) do
    TimeEntry
    |> where(user_id: ^user.id)
    |> filter_time_entries(filters)
    |> order_by(desc: :date, desc: :id)
    |> preload(project: :client)
    |> Repo.all()
  end

  defp filter_time_entries(query, filters) do
    query
    |> filter_by_date_range(filters)
    |> filter_by_project(filters)
    |> filter_by_billable(filters)
    |> filter_by_client(filters)
    |> filter_by_month(filters)
    |> filter_by_week(filters)
  end

  defp filter_by_date_range(query, %{"from_date" => from_date, "to_date" => to_date}) do
    query |> where([t], t.date >= ^from_date and t.date <= ^to_date)
  end
  defp filter_by_date_range(query, %{"from_date" => from_date}) do
    query |> where([t], t.date >= ^from_date)
  end
  defp filter_by_date_range(query, %{"to_date" => to_date}) do
    query |> where([t], t.date <= ^to_date)
  end
  defp filter_by_date_range(query, _), do: query

  defp filter_by_project(query, %{"project_id" => project_id}) when project_id != "" do
    query |> where(project_id: ^project_id)
  end
  defp filter_by_project(query, _), do: query

  defp filter_by_billable(query, %{"billable" => billable}) when is_boolean(billable) do
    query |> where(billable: ^billable)
  end
  defp filter_by_billable(query, _), do: query

  defp filter_by_client(query, %{"client_id" => client_id}) when client_id != "" do
    query 
    |> join(:inner, [t], p in Project, on: t.project_id == p.id)
    |> where([t, p], p.client_id == ^client_id)
  end
  defp filter_by_client(query, _), do: query

  defp filter_by_month(query, %{"month" => month, "year" => year}) when month != "" and year != "" do
    month_int = String.to_integer(month)
    year_int = String.to_integer(year)
    query |> where([t], fragment("CAST(strftime('%m', ?) AS INTEGER)", t.date) == ^month_int and fragment("CAST(strftime('%Y', ?) AS INTEGER)", t.date) == ^year_int)
  end
  defp filter_by_month(query, %{"month" => month}) when month != "" do
    month_int = String.to_integer(month)
    query |> where([t], fragment("CAST(strftime('%m', ?) AS INTEGER)", t.date) == ^month_int)
  end
  defp filter_by_month(query, _), do: query

  defp filter_by_week(query, %{"week" => week}) when week != "" do
    week_int = String.to_integer(week)
    query |> where([t], fragment("CAST(strftime('%W', ?) AS INTEGER) + 1", t.date) == ^week_int)
  end
  defp filter_by_week(query, _), do: query

  @doc """
  Gets a single time entry for a user.

  Raises `Ecto.NoResultsError` if the Time entry does not exist or belongs to another user.
  """
  def get_time_entry!(user, id) do
    TimeEntry
    |> where(user_id: ^user.id, id: ^id)
    |> preload(project: :client)
    |> Repo.one!()
  end

  @doc """
  Creates a time entry for a user.
  """
  def create_time_entry(user, attrs) do
    attrs = Map.put(attrs, "user_id", user.id)
    
    # Determine hourly rate if not explicitly provided
    attrs = maybe_set_hourly_rate(attrs)
    
    %TimeEntry{}
    |> TimeEntry.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a time entry.
  """
  def update_time_entry(%TimeEntry{} = time_entry, attrs) do
    # Determine hourly rate if project changes and rate not explicitly provided
    attrs = maybe_set_hourly_rate(attrs, time_entry)
    
    time_entry
    |> TimeEntry.changeset(attrs)
    |> Repo.update()
  end

  defp maybe_set_hourly_rate(attrs, existing_entry \\ nil) do
    # If hourly_rate is explicitly provided, use it
    if Map.has_key?(attrs, "hourly_rate") || Map.has_key?(attrs, :hourly_rate) do
      attrs
    else
      # Get project_id from attrs or existing entry
      project_id = 
        Map.get(attrs, "project_id") || 
        Map.get(attrs, :project_id) || 
        (existing_entry && existing_entry.project_id)
      
      if project_id do
        # Fetch project with client preloaded
        project = Repo.get(Project, project_id) |> Repo.preload(:client)
        
        if project do
          # Determine rate: project rate → client default rate → nil
          hourly_rate = 
            project.hourly_rate || 
            (project.client && project.client.default_hourly_rate)
          
          if hourly_rate do
            Map.put(attrs, "hourly_rate", hourly_rate)
          else
            attrs
          end
        else
          attrs
        end
      else
        attrs
      end
    end
  end

  @doc """
  Deletes a time entry.
  """
  def delete_time_entry(%TimeEntry{} = time_entry) do
    Repo.delete(time_entry)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking time entry changes.
  """
  def change_time_entry(%TimeEntry{} = time_entry, attrs \\ %{}) do
    TimeEntry.changeset(time_entry, attrs)
  end

  # ===== TIMER FUNCTIONS =====

  @doc """
  Starts a timer for a user.
  """
  def start_timer(user, project_id, description \\ "") do
    attrs = %{
      "user_id" => user.id,
      "project_id" => project_id,
      "description" => description,
      "date" => Date.utc_today(),
      "start_time" => Time.utc_now() |> Time.truncate(:second),
      "duration_minutes" => 0,
      "pause_duration_minutes" => 0,
      "paused_at" => nil,
      "billable" => true
    }
    
    # Determine hourly rate based on project/client settings
    attrs = maybe_set_hourly_rate(attrs)
    
    %TimeEntry{}
    |> TimeEntry.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Stops the running timer for a user.
  """
  def stop_timer(user) do
    case get_running_timer(user) do
      nil ->
        {:error, :no_timer_running}
      
      entry ->
        end_time = Time.utc_now() |> Time.truncate(:second)
        duration = Time.diff(end_time, entry.start_time, :minute)
        
        # Subtract any pause time from total duration, ensuring minimum 0
        actual_duration = max(0, duration - (entry.pause_duration_minutes || 0))
        
        entry
        |> update_time_entry(%{
          "end_time" => end_time,
          "duration_minutes" => actual_duration,
          "paused_at" => nil  # Clear paused state
        })
    end
  end

  @doc """
  Pauses the running timer for a user.
  """
  def pause_timer(user) do
    case get_running_timer(user) do
      nil ->
        {:error, :no_timer_running}
      
      entry ->
        if entry.paused_at do
          {:error, :timer_already_paused}
        else
          entry
          |> update_time_entry(%{"paused_at" => Time.utc_now() |> Time.truncate(:second)})
        end
    end
  end

  @doc """
  Resumes the paused timer for a user.
  """
  def resume_timer(user) do
    case get_running_timer(user) do
      nil ->
        {:error, :no_timer_running}
      
      entry ->
        if entry.paused_at do
          current_time = Time.utc_now() |> Time.truncate(:second)
          pause_duration_seconds = Time.diff(current_time, entry.paused_at, :second)
          # Convert to minutes and round up to ensure we capture all pause time  
          pause_duration_minutes = div(pause_duration_seconds + 59, 60)  # Round up division
          total_pause_duration = (entry.pause_duration_minutes || 0) + pause_duration_minutes
          
          entry
          |> update_time_entry(%{
            "pause_duration_minutes" => total_pause_duration,
            "paused_at" => nil
          })
        else
          {:error, :timer_not_paused}
        end
    end
  end

  @doc """
  Gets the running timer for a user (entry with start_time but no end_time).
  """
  def get_running_timer(user) do
    TimeEntry
    |> where(user_id: ^user.id)
    |> where([t], not is_nil(t.start_time) and is_nil(t.end_time))
    |> preload(project: :client)
    |> Repo.one()
  end

  # ===== REPORTING FUNCTIONS =====

  @doc """
  Returns hours by project for a user in a date range.
  """
  def hours_by_project(user, from_date, to_date) do
    TimeEntry
    |> join(:inner, [t], p in Project, on: t.project_id == p.id)
    |> where([t], t.user_id == ^user.id)
    |> where([t], t.date >= ^from_date and t.date <= ^to_date)
    |> group_by([t, p], [p.id, p.name, p.color])
    |> select([t, p], %{
      project_id: p.id,
      project_name: p.name,
      project_color: p.color,
      total_minutes: sum(t.duration_minutes),
      total_hours: fragment("CAST(SUM(?) / 60.0 AS DECIMAL(10, 2))", t.duration_minutes)
    })
    |> Repo.all()
  end

  @doc """
  Returns hours by client for a user in a date range.
  """
  def hours_by_client(user, from_date, to_date) do
    TimeEntry
    |> join(:inner, [t], p in Project, on: t.project_id == p.id)
    |> join(:inner, [t, p], c in Client, on: p.client_id == c.id)
    |> where([t], t.user_id == ^user.id)
    |> where([t], t.date >= ^from_date and t.date <= ^to_date)
    |> group_by([t, p, c], [c.id, c.name])
    |> select([t, p, c], %{
      client_id: c.id,
      client_name: c.name,
      total_minutes: sum(t.duration_minutes),
      total_hours: fragment("CAST(SUM(?) / 60.0 AS DECIMAL(10, 2))", t.duration_minutes)
    })
    |> Repo.all()
  end

  @doc """
  Returns hours by day for a user in a date range.
  """
  def hours_by_day(user, from_date, to_date) do
    TimeEntry
    |> where(user_id: ^user.id)
    |> where([t], t.date >= ^from_date and t.date <= ^to_date)
    |> group_by([t], t.date)
    |> select([t], %{
      date: t.date,
      total_minutes: sum(t.duration_minutes),
      total_hours: fragment("CAST(SUM(?) / 60.0 AS DECIMAL(10, 2))", t.duration_minutes),
      entry_count: count(t.id)
    })
    |> order_by(asc: :date)
    |> Repo.all()
  end

  @doc """
  Returns daily summary for a user on a specific date.
  """
  def daily_summary(user, date \\ Date.utc_today()) do
    entries = TimeEntry
    |> where(user_id: ^user.id, date: ^date)
    |> preload(project: :client)
    |> Repo.all()
    
    total_minutes = Enum.reduce(entries, 0, fn e, acc -> acc + (e.duration_minutes || 0) end)
    
    %{
      date: date,
      entries: entries,
      total_minutes: total_minutes,
      total_hours: Float.round(total_minutes / 60.0, 2),
      entry_count: length(entries)
    }
  end

  @doc """
  Returns weekly summary for a user.
  """
  def weekly_summary(user, week_start_date \\ Date.beginning_of_week(Date.utc_today(), :monday)) do
    week_end_date = Date.add(week_start_date, 6)
    
    daily_data = hours_by_day(user, week_start_date, week_end_date)
    total_minutes = Enum.reduce(daily_data, 0, fn d, acc -> acc + d.total_minutes end)
    
    %{
      week_start: week_start_date,
      week_end: week_end_date,
      daily_data: daily_data,
      total_minutes: total_minutes,
      total_hours: Float.round(total_minutes / 60.0, 2)
    }
  end

  @doc """
  Returns monthly summary for a user.
  """
  def monthly_summary(user, date \\ Date.utc_today()) do
    month_start_date = Date.beginning_of_month(date)
    month_end_date = Date.end_of_month(date)
    
    entries = TimeEntry
    |> where(user_id: ^user.id)
    |> where([t], t.date >= ^month_start_date and t.date <= ^month_end_date)
    |> Repo.all()
    
    total_minutes = Enum.reduce(entries, 0, fn e, acc -> acc + (e.duration_minutes || 0) end)
    entry_count = length(entries)
    
    %{
      month_start: month_start_date,
      month_end: month_end_date,
      total_minutes: total_minutes,
      total_hours: Float.round(total_minutes / 60.0, 2),
      entry_count: entry_count
    }
  end

  @doc """
  Calculates revenue for a given period.
  """
  def calculate_revenue(user, start_date, end_date) do
    entries = TimeEntry
    |> where(user_id: ^user.id)
    |> where([t], t.date >= ^start_date and t.date <= ^end_date)
    |> where([t], t.billable == true)
    |> where([t], not is_nil(t.total_amount))
    |> Repo.all()
    
    total_revenue = 
      entries
      |> Enum.reduce(Decimal.new(0), fn e, acc -> 
        if e.total_amount, do: Decimal.add(acc, e.total_amount), else: acc
      end)
    
    %{
      start_date: start_date,
      end_date: end_date,
      total_revenue: total_revenue,
      billable_entries: length(entries)
    }
  end

  @doc """
  Returns daily revenue for a user.
  """
  def daily_revenue(user, date \\ Date.utc_today()) do
    calculate_revenue(user, date, date)
  end

  @doc """
  Returns weekly revenue for a user.
  """
  def weekly_revenue(user, week_start \\ Date.beginning_of_week(Date.utc_today(), :monday)) do
    week_end = Date.add(week_start, 6)
    calculate_revenue(user, week_start, week_end)
  end

  @doc """
  Returns monthly revenue for a user.
  """
  def monthly_revenue(user, date \\ Date.utc_today()) do
    month_start = Date.beginning_of_month(date)
    month_end = Date.end_of_month(date)
    calculate_revenue(user, month_start, month_end)
  end

  @doc """
  Returns billable vs non-billable breakdown for a user in a date range.
  """
  def billable_breakdown(user, from_date, to_date) do
    TimeEntry
    |> where(user_id: ^user.id)
    |> where([t], t.date >= ^from_date and t.date <= ^to_date)
    |> group_by([t], t.billable)
    |> select([t], %{
      billable: t.billable,
      total_minutes: sum(t.duration_minutes),
      total_hours: fragment("CAST(SUM(?) / 60.0 AS DECIMAL(10, 2))", t.duration_minutes),
      entry_count: count(t.id)
    })
    |> Repo.all()
  end

  # ===== EXPORT FUNCTIONS =====

  @doc """
  Exports time entries to CSV format for a user with optional filters.
  """
  def export_time_entries_to_csv(user, filters \\ %{}) do
    time_entries = list_time_entries(user, filters)
    
    csv_header = "Date,Company,Project,Description,Start Time,End Time,Duration,Pause Duration,Billable,Hourly Rate (DKK),Total Amount (DKK),Week,Month\n"
    
    csv_rows = 
      time_entries
      |> Enum.map(&format_time_entry_for_csv/1)
      |> Enum.map(&csv_row_to_string/1)
      |> Enum.join("\n")
    
    csv_header <> csv_rows
  end

  defp format_time_entry_for_csv(time_entry) do
    [
      Calendar.strftime(time_entry.date, "%d.%m.%y"),
      time_entry.project.client.name,
      time_entry.project.name,
      time_entry.description || "",
      format_time_for_csv(time_entry.start_time),
      format_time_for_csv(time_entry.end_time),
      format_duration_for_csv(time_entry.duration_minutes),
      format_duration_for_csv(time_entry.pause_duration_minutes || 0),
      if(time_entry.billable, do: "Yes", else: "No"),
      format_rate_for_csv(time_entry.hourly_rate),
      format_amount_for_csv(time_entry.total_amount, time_entry.billable),
      "W#{format_week_for_csv(time_entry.date)}",
      format_month_for_csv(time_entry.date)
    ]
  end

  defp format_time_for_csv(nil), do: ""
  defp format_time_for_csv(time) do
    "#{String.pad_leading(to_string(time.hour), 2, "0")}:#{String.pad_leading(to_string(time.minute), 2, "0")}"
  end

  defp format_duration_for_csv(nil), do: "0:00"
  defp format_duration_for_csv(0), do: "0:00" 
  defp format_duration_for_csv(minutes) do
    hours = div(minutes, 60)
    mins = rem(minutes, 60)
    "#{hours}:#{String.pad_leading(to_string(mins), 2, "0")}"
  end

  defp format_week_for_csv(date) do
    {_year, week} = :calendar.iso_week_number({date.year, date.month, date.day})
    String.pad_leading(to_string(week), 2, "0")
  end

  defp format_month_for_csv(date) do
    case date.month do
      1 -> "Jan"
      2 -> "Feb" 
      3 -> "Mar"
      4 -> "Apr"
      5 -> "Maj"
      6 -> "Jun"
      7 -> "Jul"
      8 -> "Aug"
      9 -> "Sep"
      10 -> "Okt"
      11 -> "Nov"
      12 -> "Dec"
    end
  end

  defp format_rate_for_csv(nil), do: ""
  defp format_rate_for_csv(rate), do: to_string(rate)

  defp format_amount_for_csv(nil, _billable), do: ""
  defp format_amount_for_csv(_amount, false), do: "0.00"
  defp format_amount_for_csv(amount, true), do: to_string(amount)

  defp csv_row_to_string(row) do
    row
    |> Enum.map(&escape_csv_field/1)
    |> Enum.join(",")
  end

  defp escape_csv_field(field) do
    field_str = to_string(field)
    if String.contains?(field_str, [",", "\"", "\n"]) do
      "\"#{String.replace(field_str, "\"", "\"\"")}\"" 
    else
      field_str
    end
  end
end