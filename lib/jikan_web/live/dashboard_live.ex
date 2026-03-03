defmodule JikanWeb.DashboardLive do
  use JikanWeb, :live_view
  alias Jikan.Tracking
  alias Jikan.Accounts.User

  @impl true
  def mount(_params, _session, socket) do
    user = socket.assigns.current_user
    
    if connected?(socket) do
      # Check for any running timer
      case Tracking.get_running_timer(user) do
        nil ->
          {:ok, assign_dashboard_data(socket, user, nil, 0)}
        
        entry ->
          # Set up timer tick for running timer
          :timer.send_interval(1000, self(), :tick)
          elapsed = calculate_elapsed(entry.start_time)
          {:ok, assign_dashboard_data(socket, user, entry, elapsed)}
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
      
      entry ->
        elapsed = calculate_elapsed(entry.start_time)
        {:noreply, assign(socket, :elapsed, elapsed)}
    end
  end

  @impl true
  def handle_event("start_timer", %{"project_id" => project_id, "description" => description}, socket) do
    user = socket.assigns.current_user
    
    case Tracking.start_timer(user, project_id, description) do
      {:ok, entry} ->
        # Start the timer tick
        :timer.send_interval(1000, self(), :tick)
        
        {:noreply,
         socket
         |> assign(:running_timer, entry)
         |> assign(:elapsed, 0)
         |> put_flash(:info, "Timer started")}
      
      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Failed to start timer")}
    end
  end

  @impl true
  def handle_event("stop_timer", _params, socket) do
    user = socket.assigns.current_user
    
    case Tracking.stop_timer(user) do
      {:ok, _entry} ->
        # Refresh dashboard data
        today_summary = Tracking.daily_summary(user)
        recent_entries = 
          user
          |> Tracking.list_time_entries(%{})
          |> Enum.take(5)
        
        {:noreply,
         socket
         |> assign(:running_timer, nil)
         |> assign(:elapsed, 0)
         |> assign(:today_summary, today_summary)
         |> assign(:recent_entries, recent_entries)
         |> put_flash(:info, "Timer stopped")}
      
      {:error, :no_timer_running} ->
        {:noreply, put_flash(socket, :error, "No timer is running")}
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

  defp calculate_elapsed(start_time) do
    Time.diff(Time.utc_now(), start_time, :second)
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
    <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
      <h1 class="text-3xl font-bold text-gray-900 mb-8">Dashboard</h1>
      
      <!-- Running Timer Widget -->
      <div :if={@running_timer} class="mb-8 bg-blue-50 border-2 border-blue-200 rounded-lg p-6">
        <div class="flex items-center justify-between">
          <div>
            <h3 class="text-lg font-semibold text-blue-900">Timer Running</h3>
            <p class="text-blue-700">
              <%= @running_timer.project.name %> - <%= @running_timer.project.client.name %>
            </p>
            <p :if={@running_timer.description} class="text-sm text-blue-600 mt-1">
              <%= @running_timer.description %>
            </p>
          </div>
          <div class="text-right">
            <div class="text-3xl font-mono font-bold text-blue-900">
              <%= format_duration(@elapsed) %>
            </div>
            <button 
              phx-click="stop_timer"
              class="mt-2 bg-red-600 text-white px-4 py-2 rounded hover:bg-red-700 transition"
            >
              Stop Timer
            </button>
          </div>
        </div>
      </div>

      <!-- Start Timer Form (when no timer running) -->
      <div :if={!@running_timer && length(@projects) > 0} class="mb-8 bg-gray-50 rounded-lg p-6">
        <h3 class="text-lg font-semibold mb-4">Start Timer</h3>
        <form phx-submit="start_timer" class="flex gap-4">
          <select name="project_id" required class="flex-1 rounded border-gray-300">
            <option value="">Select a project...</option>
            <%= for project <- @projects do %>
              <option value={project.id}>
                <%= project.name %> (<%= project.client.name %>)
              </option>
            <% end %>
          </select>
          <input 
            type="text" 
            name="description" 
            placeholder="What are you working on?" 
            class="flex-1 rounded border-gray-300"
          />
          <button type="submit" class="bg-blue-600 text-white px-6 py-2 rounded hover:bg-blue-700 transition">
            Start
          </button>
        </form>
      </div>

      <!-- Today's Summary -->
      <div class="grid grid-cols-1 md:grid-cols-3 gap-6 mb-8">
        <div class="bg-white rounded-lg shadow p-6">
          <h3 class="text-sm font-medium text-gray-500 uppercase tracking-wider">Today's Hours</h3>
          <p class="text-3xl font-bold text-gray-900 mt-2">
            <%= format_minutes(@today_summary.total_minutes) %>
          </p>
        </div>
        <div class="bg-white rounded-lg shadow p-6">
          <h3 class="text-sm font-medium text-gray-500 uppercase tracking-wider">Today's Entries</h3>
          <p class="text-3xl font-bold text-gray-900 mt-2">
            <%= @today_summary.entry_count %>
          </p>
        </div>
        <div class="bg-white rounded-lg shadow p-6">
          <h3 class="text-sm font-medium text-gray-500 uppercase tracking-wider">Week Total</h3>
          <p class="text-3xl font-bold text-gray-900 mt-2">
            <%= format_minutes(@weekly_summary.total_minutes) %>
          </p>
        </div>
      </div>

      <!-- This Week's Hours -->
      <div class="bg-white rounded-lg shadow mb-8">
        <div class="p-6">
          <h3 class="text-lg font-semibold mb-4">This Week's Hours</h3>
          <div class="space-y-3">
            <%= for day_data <- @weekly_summary.daily_data do %>
              <div class="flex items-center justify-between">
                <span class="text-sm font-medium text-gray-600">
                  <%= Calendar.strftime(day_data.date, "%A, %B %d") %>
                </span>
                <div class="flex items-center gap-4">
                  <div class="w-48 bg-gray-200 rounded-full h-2">
                    <div 
                      class="bg-blue-600 h-2 rounded-full"
                      style={"width: #{min(100, day_data.total_minutes / 480 * 100)}%"}
                    ></div>
                  </div>
                  <span class="text-sm font-semibold text-gray-900 w-16 text-right">
                    <%= format_minutes(day_data.total_minutes) %>
                  </span>
                </div>
              </div>
            <% end %>
          </div>
        </div>
      </div>

      <!-- Quick Entry Form -->
      <div :if={length(@projects) > 0} class="bg-white rounded-lg shadow mb-8">
        <div class="p-6">
          <h3 class="text-lg font-semibold mb-4">Quick Add Time Entry</h3>
          <.form for={@quick_entry_form} phx-submit="quick_add" class="space-y-4">
            <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
              <div>
                <label class="block text-sm font-medium text-gray-700 mb-1">Date</label>
                <input 
                  type="date" 
                  name="time_entry[date]" 
                  value={Date.utc_today()} 
                  required 
                  class="w-full rounded border-gray-300"
                />
              </div>
              <div>
                <label class="block text-sm font-medium text-gray-700 mb-1">Project</label>
                <select name="time_entry[project_id]" required class="w-full rounded border-gray-300">
                  <option value="">Select a project...</option>
                  <%= for project <- @projects do %>
                    <option value={project.id}>
                      <%= project.name %> (<%= project.client.name %>)
                    </option>
                  <% end %>
                </select>
              </div>
              <div>
                <label class="block text-sm font-medium text-gray-700 mb-1">Duration (minutes)</label>
                <input 
                  type="number" 
                  name="time_entry[duration_minutes]" 
                  min="1"
                  required 
                  placeholder="90"
                  class="w-full rounded border-gray-300"
                />
              </div>
              <div>
                <label class="block text-sm font-medium text-gray-700 mb-1">Description</label>
                <input 
                  type="text" 
                  name="time_entry[description]" 
                  placeholder="What did you work on?"
                  class="w-full rounded border-gray-300"
                />
              </div>
            </div>
            <div class="flex items-center gap-4">
              <label class="flex items-center">
                <input 
                  type="checkbox" 
                  name="time_entry[billable]" 
                  checked 
                  class="rounded border-gray-300 text-blue-600"
                />
                <span class="ml-2 text-sm text-gray-700">Billable</span>
              </label>
              <button type="submit" class="bg-blue-600 text-white px-6 py-2 rounded hover:bg-blue-700 transition">
                Add Entry
              </button>
            </div>
          </.form>
        </div>
      </div>

      <!-- Recent Entries -->
      <div class="bg-white rounded-lg shadow">
        <div class="p-6">
          <div class="flex items-center justify-between mb-4">
            <h3 class="text-lg font-semibold">Recent Entries</h3>
            <.link navigate={~p"/time-entries"} class="text-blue-600 hover:text-blue-700 text-sm">
              View all →
            </.link>
          </div>
          
          <% entries_empty = length(@recent_entries) == 0 %>
          <div :if={entries_empty} class="text-center py-8 text-gray-500">
            No time entries yet. Start tracking your time!
          </div>
          
          <div :if={!entries_empty} class="space-y-3">
            <%= for entry <- @recent_entries do %>
              <div class="border rounded-lg p-4 hover:bg-gray-50 transition">
                <div class="flex items-start justify-between">
                  <div class="flex-1">
                    <div class="flex items-center gap-2">
                      <span 
                        class="inline-block w-3 h-3 rounded-full"
                        style={"background-color: #{entry.project.color}"}
                      ></span>
                      <span class="font-medium text-gray-900">
                        <%= entry.project.name %>
                      </span>
                      <span class="text-gray-500 text-sm">
                        • <%= entry.project.client.name %>
                      </span>
                    </div>
                    <p :if={entry.description} class="text-sm text-gray-600 mt-1">
                      <%= entry.description %>
                    </p>
                    <div class="flex items-center gap-4 mt-2 text-sm text-gray-500">
                      <span><%= entry.date %></span>
                      <span><%= format_minutes(entry.duration_minutes) %></span>
                      <span :if={entry.billable} class="text-green-600">Billable</span>
                      <span :if={!entry.billable} class="text-gray-400">Non-billable</span>
                    </div>
                  </div>
                  <div class="flex items-center gap-2">
                    <.link 
                      navigate={~p"/time-entries/#{entry.id}/edit"}
                      class="text-blue-600 hover:text-blue-700 text-sm"
                    >
                      Edit
                    </.link>
                    <button 
                      phx-click="delete_entry"
                      phx-value-id={entry.id}
                      data-confirm="Are you sure?"
                      class="text-red-600 hover:text-red-700 text-sm"
                    >
                      Delete
                    </button>
                  </div>
                </div>
              </div>
            <% end %>
          </div>
        </div>
      </div>

      <!-- Empty state for users without projects -->
      <div :if={length(@projects) == 0} class="bg-yellow-50 border border-yellow-200 rounded-lg p-6 text-center">
        <p class="text-yellow-800">
          You need to create clients and projects before you can start tracking time.
        </p>
        <%= if User.manager_or_above?(@current_user) do %>
          <div class="mt-4 space-x-4">
            <.link navigate={~p"/clients/new"} class="text-blue-600 hover:underline">
              Create your first client →
            </.link>
            <.link navigate={~p"/projects/new"} class="text-blue-600 hover:underline">
              Create your first project →
            </.link>
          </div>
        <% else %>
          <p class="text-sm text-yellow-700 mt-2">
            Please contact your manager to set up clients and projects for you.
          </p>
        <% end %>
      </div>
    </div>
    """
  end
end