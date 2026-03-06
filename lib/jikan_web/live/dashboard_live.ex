defmodule JikanWeb.DashboardLive do
  use JikanWeb, :live_view
  alias Jikan.Tracking
  alias Jikan.Accounts.User

  @impl true
  def mount(_params, _session, socket) do
    user = socket.assigns.current_user
    
    socket = assign(socket, :timer_ref, nil)
    
    if connected?(socket) do
      # Check for any running timer
      case Tracking.get_running_timer(user) do
        nil ->
          {:ok, assign_dashboard_data(socket, user, nil, 0)}
        
        entry ->
          # Set up timer tick for running timer
          {:ok, timer_ref} = :timer.send_interval(1000, self(), :tick)
          elapsed = calculate_elapsed(entry)
          {:ok, 
           socket
           |> assign(:timer_ref, timer_ref)
           |> assign_dashboard_data(user, entry, elapsed)}
      end
    else
      {:ok, assign_dashboard_data(socket, user, nil, 0)}
    end
  end

  defp assign_dashboard_data(socket, user, running_timer, elapsed) do
    today_summary = Tracking.daily_summary(user)
    weekly_summary = Tracking.weekly_summary(user)
    projects = Tracking.list_projects(user, archived: false)
    recent_entries = 
      user
      |> Tracking.list_time_entries(%{})
      |> Enum.take(5)
    
    socket
    |> assign(:running_timer, running_timer)
    |> assign(:elapsed, elapsed)
    |> assign(:today_summary, today_summary)
    |> assign(:weekly_summary, weekly_summary)
    |> assign(:projects, projects)
    |> assign(:recent_entries, recent_entries)
    |> assign(:quick_entry_form, to_form(Tracking.change_time_entry(%Tracking.TimeEntry{}, %{})))
  end

  @impl true
  def handle_info(:tick, socket) do
    case socket.assigns.running_timer do
      nil ->
        {:noreply, socket}
      
      _entry ->
        # Refetch the entry to ensure we have fresh data
        user = socket.assigns.current_user
        fresh_entry = Tracking.get_running_timer(user)
        
        if fresh_entry do
          elapsed = calculate_elapsed(fresh_entry)
          {:noreply, 
           socket
           |> assign(:running_timer, fresh_entry)
           |> assign(:elapsed, elapsed)}
        else
          # Timer was stopped elsewhere
          {:noreply, assign(socket, running_timer: nil, elapsed: 0)}
        end
    end
  end

  @impl true
  def handle_event("start_timer", params, socket) do
    IO.inspect(params, label: "START_TIMER_PARAMS")
    
    user = socket.assigns.current_user
    project_id = params["project_id"]
    description = params["description"] || ""
    
    IO.inspect({:starting_timer, project_id, description}, label: "START_TIMER")
    
    case Tracking.start_timer(user, project_id, description) do
      {:ok, entry} ->
        IO.inspect(entry, label: "TIMER_CREATED")
        
        # Cancel any existing timer
        if socket.assigns[:timer_ref] do
          :timer.cancel(socket.assigns.timer_ref)
        end
        
        # Fetch the entry with all preloaded associations
        entry_with_preloads = Tracking.get_running_timer(user)
        IO.inspect(entry_with_preloads, label: "FETCHED_ENTRY_WITH_PRELOADS")
        
        # Start the timer tick
        {:ok, timer_ref} = :timer.send_interval(1000, self(), :tick)
        IO.inspect(timer_ref, label: "TIMER_REF")
        
        {:noreply,
         socket
         |> assign(:timer_ref, timer_ref)
         |> assign(:running_timer, entry_with_preloads)
         |> assign(:elapsed, 0)
         |> put_flash(:info, "Timer started")}
      
      {:error, changeset} ->
        IO.inspect(changeset, label: "START_TIMER_CHANGESET")
        IO.inspect(changeset.errors, label: "START_TIMER_ERROR")
        {:noreply, put_flash(socket, :error, "Failed to start timer")}
    end
  end

  @impl true
  def handle_event("stop_timer", _params, socket) do
    user = socket.assigns.current_user
    
    case Tracking.stop_timer(user) do
      {:ok, _entry} ->
        # Cancel the timer interval
        if socket.assigns[:timer_ref] do
          :timer.cancel(socket.assigns.timer_ref)
        end
        
        # Refresh dashboard data
        today_summary = Tracking.daily_summary(user)
        recent_entries = 
          user
          |> Tracking.list_time_entries(%{})
          |> Enum.take(5)
        
        {:noreply,
         socket
         |> assign(:timer_ref, nil)
         |> assign(:running_timer, nil)
         |> assign(:elapsed, 0)
         |> assign(:today_summary, today_summary)
         |> assign(:recent_entries, recent_entries)
         |> put_flash(:info, "Timer stopped")}
      
      {:error, :no_timer_running} ->
        {:noreply, put_flash(socket, :error, "No timer is running")}
      
      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Failed to stop timer")}
    end
  end

  @impl true
  def handle_event("pause_timer", _params, socket) do
    user = socket.assigns.current_user
    
    case Tracking.pause_timer(user) do
      {:ok, _entry} ->
        # Fetch the updated entry with all preloaded associations
        entry = Tracking.get_running_timer(user)
        elapsed = calculate_elapsed(entry)
        
        {:noreply,
         socket
         |> assign(:running_timer, entry)
         |> assign(:elapsed, elapsed)
         |> put_flash(:info, "Timer paused")}
      
      {:error, :no_timer_running} ->
        {:noreply, put_flash(socket, :error, "No timer is running")}
      
      {:error, :timer_already_paused} ->
        {:noreply, put_flash(socket, :error, "Timer is already paused")}
    end
  end

  @impl true
  def handle_event("resume_timer", _params, socket) do
    user = socket.assigns.current_user
    
    case Tracking.resume_timer(user) do
      {:ok, _entry} ->
        # Fetch the updated entry with all preloaded associations
        entry = Tracking.get_running_timer(user)
        elapsed = calculate_elapsed(entry)
        
        {:noreply,
         socket
         |> assign(:running_timer, entry)
         |> assign(:elapsed, elapsed)
         |> put_flash(:info, "Timer resumed")}
      
      {:error, :no_timer_running} ->
        {:noreply, put_flash(socket, :error, "No timer is running")}
      
      {:error, :timer_not_paused} ->
        {:noreply, put_flash(socket, :error, "Timer is not paused")}
      
      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Failed to resume timer")}
    end
  end

  @impl true
  def handle_event("quick_add", %{"time_entry" => time_entry_params}, socket) do
    user = socket.assigns.current_user
    
    case Tracking.create_time_entry(user, time_entry_params) do
      {:ok, _entry} ->
        # Refresh dashboard data
        today_summary = Tracking.daily_summary(user)
        recent_entries = 
          user
          |> Tracking.list_time_entries(%{})
          |> Enum.take(5)
        
        {:noreply,
         socket
         |> assign(:today_summary, today_summary)
         |> assign(:recent_entries, recent_entries)
         |> assign(:quick_entry_form, to_form(Tracking.change_time_entry(%Tracking.TimeEntry{}, %{})))
         |> put_flash(:info, "Time entry added")}
      
      {:error, changeset} ->
        {:noreply, assign(socket, :quick_entry_form, to_form(changeset))}
    end
  end

  @impl true
  def handle_event("delete_entry", %{"id" => id}, socket) do
    user = socket.assigns.current_user
    entry = Tracking.get_time_entry!(user, id)
    
    case Tracking.delete_time_entry(entry) do
      {:ok, _} ->
        # Refresh dashboard data
        today_summary = Tracking.daily_summary(user)
        recent_entries = 
          user
          |> Tracking.list_time_entries(%{})
          |> Enum.take(5)
        
        {:noreply,
         socket
         |> assign(:today_summary, today_summary)
         |> assign(:recent_entries, recent_entries)
         |> put_flash(:info, "Time entry deleted")}
      
      {:error, _} ->
        {:noreply, put_flash(socket, :error, "Failed to delete entry")}
    end
  end

  defp calculate_elapsed(entry) do
    current_time = Time.utc_now()
    total_elapsed = Time.diff(current_time, entry.start_time, :second)
    
    # Calculate current pause duration if timer is paused
    current_pause_duration = if entry.paused_at do
      Time.diff(current_time, entry.paused_at, :second)
    else
      0
    end
    
    # Total paused time = previously accumulated paused time + current pause duration
    total_paused = ((entry.pause_duration_minutes || 0) * 60) + current_pause_duration
    
    # Actual elapsed time = total time - paused time
    max(0, total_elapsed - total_paused)
  end

  defp format_duration(seconds) when seconds < 0, do: "00:00:00"
  defp format_duration(seconds) do
    hours = div(seconds, 3600)
    minutes = div(rem(seconds, 3600), 60)
    seconds = rem(seconds, 60)
    
    :io_lib.format("~2..0B:~2..0B:~2..0B", [hours, minutes, seconds])
    |> to_string()
  end

  defp format_minutes(nil), do: "0:00"
  defp format_minutes(minutes) do
    hours = div(minutes, 60)
    mins = rem(minutes, 60)
    "#{hours}:#{String.pad_leading(to_string(mins), 2, "0")}"
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="p-6">
      <div class="hero bg-base-200 rounded-box mb-6">
        <div class="hero-content text-center">
          <div class="max-w-md">
            <h1 class="text-4xl font-bold flex items-center justify-center gap-3">
              <.icon name="hero-home" class="size-10" />
              Dashboard
            </h1>
            <p class="py-2 text-base-content/70">Track your time and manage your projects</p>
          </div>
        </div>
      </div>
      
      <!-- Running Timer Widget -->
      <div :if={@running_timer} class={"card #{if @running_timer.paused_at, do: "bg-warning text-warning-content", else: "bg-info text-info-content"} mb-6 shadow-lg"}>
        <div class="card-body">
          <div class="flex items-center justify-between">
            <div>
              <h2 class="card-title text-2xl flex items-center gap-3">
                <%= if @running_timer.paused_at do %>
                  <.icon name="hero-pause-circle" class="size-8" />
                  Timer Paused
                <% else %>
                  <.icon name="hero-play-circle" class="size-8" />
                  Timer Running
                <% end %>
              </h2>
              <p class="text-lg opacity-90">
                <%= @running_timer.project.name %> - <%= @running_timer.project.client.name %>
              </p>
              <p :if={@running_timer.description} class="opacity-80 mt-1">
                <%= @running_timer.description %>
              </p>
            </div>
            <div class="text-right">
              <div class="text-5xl font-mono font-bold countdown">
                <%= format_duration(@elapsed) %>
              </div>
              <div class="card-actions justify-end mt-4">
                <%= if @running_timer.paused_at do %>
                  <button 
                    phx-click="resume_timer"
                    class="btn btn-success gap-2"
                  >
                    <.icon name="hero-play" class="size-5" />
                    Resume
                  </button>
                <% else %>
                  <button 
                    phx-click="pause_timer"
                    class="btn btn-warning gap-2"
                  >
                    <.icon name="hero-pause" class="size-5" />
                    Pause
                  </button>
                <% end %>
                <button 
                  phx-click="stop_timer"
                  class="btn btn-error gap-2"
                >
                  <.icon name="hero-stop-circle" class="size-5" />
                  Stop
                </button>
              </div>
            </div>
          </div>
        </div>
      </div>

      <!-- Start Timer Form (when no timer running) -->
      <div :if={!@running_timer && length(@projects) > 0} class="card bg-base-100 shadow-lg mb-6">
        <div class="card-body">
          <h2 class="card-title text-xl flex items-center gap-2">
            <.icon name="hero-play" class="size-6" />
            Start Timer
          </h2>
          <form phx-submit="start_timer" class="form-control w-full">
            <div class="flex flex-col lg:flex-row gap-4">
              <div class="form-control w-full lg:w-1/2">
                <label class="label">
                  <span class="label-text">Project</span>
                </label>
                <select name="project_id" required class="select select-bordered w-full">
                  <option disabled selected value="">Select a project...</option>
                  <%= for project <- @projects do %>
                    <option value={project.id}>
                      <%= project.name %> (<%= project.client.name %>)
                    </option>
                  <% end %>
                </select>
              </div>
              <div class="form-control w-full lg:w-1/2">
                <label class="label">
                  <span class="label-text">Description</span>
                </label>
                <input 
                  type="text" 
                  name="description" 
                  placeholder="What are you working on?" 
                  class="input input-bordered w-full"
                />
              </div>
            </div>
            <div class="card-actions justify-end mt-4">
              <button type="submit" class="btn btn-primary gap-2">
                <.icon name="hero-play-circle" class="size-5" />
                Start Timer
              </button>
            </div>
          </form>
        </div>
      </div>

      <!-- Today's Summary -->
      <div class="grid grid-cols-1 md:grid-cols-3 gap-6 mb-6">
        <div class="stats shadow bg-base-100">
          <div class="stat">
            <div class="stat-figure text-primary">
              <.icon name="hero-clock" class="size-8" />
            </div>
            <div class="stat-title">Today's Hours</div>
            <div class="stat-value text-primary">
              <%= format_minutes(@today_summary.total_minutes) %>
            </div>
            <div class="stat-desc">Time tracked today</div>
          </div>
        </div>
        
        <div class="stats shadow bg-base-100">
          <div class="stat">
            <div class="stat-figure text-secondary">
              <.icon name="hero-document-text" class="size-8" />
            </div>
            <div class="stat-title">Today's Entries</div>
            <div class="stat-value text-secondary">
              <%= @today_summary.entry_count %>
            </div>
            <div class="stat-desc">Entries logged today</div>
          </div>
        </div>
        
        <div class="stats shadow bg-base-100">
          <div class="stat">
            <div class="stat-figure text-accent">
              <.icon name="hero-calendar-days" class="size-8" />
            </div>
            <div class="stat-title">Week Total</div>
            <div class="stat-value text-accent">
              <%= format_minutes(@weekly_summary.total_minutes) %>
            </div>
            <div class="stat-desc">Hours this week</div>
          </div>
        </div>
      </div>

      <!-- This Week's Hours -->
      <div class="card bg-base-100 shadow-lg mb-6">
        <div class="card-body">
          <h2 class="card-title text-xl flex items-center gap-2">
            <.icon name="hero-chart-bar" class="size-6" />
            This Week's Hours
          </h2>
          <div class="space-y-4 mt-4">
            <%= for day_data <- @weekly_summary.daily_data do %>
              <div class="flex items-center justify-between">
                <span class="text-sm font-medium w-32">
                  <%= Calendar.strftime(day_data.date, "%A, %b %d") %>
                </span>
                <div class="flex items-center gap-4 flex-1">
                  <progress 
                    class="progress progress-primary w-48" 
                    value={day_data.total_minutes} 
                    max="480"
                  ></progress>
                  <span class="text-sm font-semibold w-16 text-right badge badge-primary badge-outline">
                    <%= format_minutes(day_data.total_minutes) %>
                  </span>
                </div>
              </div>
            <% end %>
          </div>
        </div>
      </div>

      <!-- Quick Entry Form -->
      <div :if={length(@projects) > 0} class="card bg-base-100 shadow-lg mb-6">
        <div class="card-body">
          <h2 class="card-title text-xl flex items-center gap-2">
            <.icon name="hero-plus-circle" class="size-6" />
            Quick Add Time Entry
          </h2>
          <.form for={@quick_entry_form} phx-submit="quick_add" class="space-y-4">
            <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
              <div class="form-control w-full">
                <label class="label">
                  <span class="label-text">Date</span>
                </label>
                <input 
                  type="date" 
                  name="time_entry[date]" 
                  value={Date.utc_today()} 
                  required 
                  class="input input-bordered w-full"
                />
              </div>
              <div class="form-control w-full">
                <label class="label">
                  <span class="label-text">Project</span>
                </label>
                <select name="time_entry[project_id]" required class="select select-bordered w-full">
                  <option disabled selected value="">Select a project...</option>
                  <%= for project <- @projects do %>
                    <option value={project.id}>
                      <%= project.name %> (<%= project.client.name %>)
                    </option>
                  <% end %>
                </select>
              </div>
              <div class="form-control w-full">
                <label class="label">
                  <span class="label-text">Duration (minutes)</span>
                </label>
                <input 
                  type="number" 
                  name="time_entry[duration_minutes]" 
                  min="1"
                  required 
                  placeholder="90"
                  class="input input-bordered w-full"
                />
              </div>
              <div class="form-control w-full">
                <label class="label">
                  <span class="label-text">Description</span>
                </label>
                <input 
                  type="text" 
                  name="time_entry[description]" 
                  placeholder="What did you work on?"
                  class="input input-bordered w-full"
                />
              </div>
            </div>
            <div class="flex items-center justify-between mt-6">
              <div class="form-control">
                <label class="label cursor-pointer gap-2">
                  <input 
                    type="checkbox" 
                    name="time_entry[billable]" 
                    checked 
                    class="checkbox checkbox-primary"
                  />
                  <span class="label-text">Billable</span>
                </label>
              </div>
              <button type="submit" class="btn btn-primary gap-2">
                <.icon name="hero-plus" class="size-5" />
                Add Entry
              </button>
            </div>
          </.form>
        </div>
      </div>

      <!-- Recent Entries -->
      <div class="card bg-base-100 shadow-lg">
        <div class="card-body">
          <div class="flex items-center justify-between mb-4">
            <h2 class="card-title text-xl flex items-center gap-2">
              <.icon name="hero-list-bullet" class="size-6" />
              Recent Entries
            </h2>
            <.link navigate={~p"/time-entries"} class="btn btn-ghost btn-sm gap-2">
              View all
              <.icon name="hero-arrow-right" class="size-4" />
            </.link>
          </div>
          
          <% entries_empty = length(@recent_entries) == 0 %>
          <div :if={entries_empty} class="text-center py-12">
            <.icon name="hero-clock" class="size-16 mx-auto text-base-300 mb-4" />
            <p class="text-base-content/70 text-lg mb-2">No time entries yet</p>
            <p class="text-base-content/50">Start tracking your time to see recent entries here!</p>
          </div>
          
          <div :if={!entries_empty} class="space-y-3">
            <%= for entry <- @recent_entries do %>
              <div class="card bg-base-200 hover:bg-base-300 transition-colors">
                <div class="card-body p-4">
                  <div class="flex items-start justify-between">
                    <div class="flex-1">
                      <div class="flex items-center gap-3 mb-2">
                        <div class="avatar avatar-placeholder">
                          <div class="text-white w-8 rounded-full" style={"background-color: #{entry.project.color}"}>
                            <span class="text-xs"><%= String.slice(entry.project.name, 0..1) |> String.upcase %></span>
                          </div>
                        </div>
                        <div>
                          <span class="font-semibold">
                            <%= entry.project.name %>
                          </span>
                          <span class="text-base-content/70 text-sm ml-2">
                            • <%= entry.project.client.name %>
                          </span>
                        </div>
                      </div>
                      <p :if={entry.description} class="text-sm text-base-content/80 mb-2 ml-11">
                        <%= entry.description %>
                      </p>
                      <div class="flex items-center gap-3 ml-11">
                        <div class="badge badge-outline badge-sm">
                          <%= entry.date %>
                        </div>
                        <div class="flex flex-col items-start">
                          <div class="badge badge-primary badge-sm">
                            <%= format_minutes(entry.duration_minutes) %>
                          </div>
                          <%= if entry.pause_duration_minutes && entry.pause_duration_minutes > 0 do %>
                            <div class="badge badge-warning badge-xs mt-1">
                              <.icon name="hero-pause-circle" class="size-3 mr-1" />
                              <%= format_minutes(entry.pause_duration_minutes) %>
                            </div>
                          <% end %>
                        </div>
                        <div class={"badge badge-sm #{if entry.billable, do: "badge-success", else: "badge-ghost"}"}>
                          <%= if entry.billable, do: "Billable", else: "Non-billable" %>
                        </div>
                      </div>
                    </div>
                    <div class="dropdown dropdown-end">
                      <div tabindex="0" role="button" class="btn btn-ghost btn-sm">
                        <.icon name="hero-ellipsis-vertical" class="size-4" />
                      </div>
                      <ul tabindex="0" class="dropdown-content menu bg-base-100 rounded-box z-[1] w-52 p-2 shadow">
                        <li>
                          <.link navigate={~p"/time-entries/#{entry.id}/edit"} class="flex items-center gap-2">
                            <.icon name="hero-pencil" class="size-4" />
                            Edit
                          </.link>
                        </li>
                        <li>
                          <button 
                            phx-click="delete_entry"
                            phx-value-id={entry.id}
                            data-confirm="Are you sure?"
                            class="flex items-center gap-2 text-error"
                          >
                            <.icon name="hero-trash" class="size-4" />
                            Delete
                          </button>
                        </li>
                      </ul>
                    </div>
                  </div>
                </div>
              </div>
            <% end %>
          </div>
        </div>
      </div>

      <!-- Empty state for users without projects -->
      <div :if={length(@projects) == 0} class="alert alert-warning">
        <.icon name="hero-exclamation-triangle" class="size-6" />
        <div>
          <h3 class="font-bold">No Projects Available</h3>
          <div class="text-sm">
            You need to create clients and projects before you can start tracking time.
          </div>
          <%= if User.manager_or_above?(@current_user) do %>
            <div class="flex gap-2 mt-3">
              <.link navigate={~p"/clients/new"} class="btn btn-sm btn-primary">
                Create Client
              </.link>
              <.link navigate={~p"/projects/new"} class="btn btn-sm btn-outline btn-primary">
                Create Project
              </.link>
            </div>
          <% else %>
            <div class="text-xs mt-2 opacity-80">
              Please contact your manager to set up clients and projects for you.
            </div>
          <% end %>
        </div>
      </div>
    </div>
    """
  end
end