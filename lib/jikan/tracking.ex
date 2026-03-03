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
    
    %TimeEntry{}
    |> TimeEntry.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a time entry.
  """
  def update_time_entry(%TimeEntry{} = time_entry, attrs) do
    time_entry
    |> TimeEntry.changeset(attrs)
    |> Repo.update()
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
      "billable" => true
    }
    
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
        
        entry
        |> update_time_entry(%{
          "end_time" => end_time,
          "duration_minutes" => duration
        })
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
end