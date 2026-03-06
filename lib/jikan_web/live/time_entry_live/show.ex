defmodule JikanWeb.TimeEntryLive.Show do
  use JikanWeb, :live_view

  alias Jikan.Tracking

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <div class="p-6">
        <div class="breadcrumbs text-sm mb-6">
          <ul>
            <li>
              <.link navigate={~p"/time-entries"} class="btn btn-ghost btn-sm gap-2">
                <.icon name="hero-arrow-left" class="size-4" />
                Time Entries
              </.link>
            </li>
            <li>Entry Details</li>
          </ul>
        </div>
        
        <.header>
          <.icon name="hero-clock" class="size-8 inline" /> Time Entry Details
          <:subtitle>
            {Calendar.strftime(@time_entry.date, "%d.%m.%y")}
          </:subtitle>
          <:actions>
            <.button variant="primary" navigate={~p"/time-entries/#{@time_entry}/edit?return_to=show"} class="gap-2">
              <.icon name="hero-pencil-square" class="size-5" />
              Edit Entry
            </.button>
          </:actions>
        </.header>
        
        <div class="grid grid-cols-1 lg:grid-cols-2 gap-6">
          <!-- Main Details Card -->
          <div class="card bg-base-100 shadow-lg">
            <div class="card-body">
              <h2 class="card-title text-lg">
                <.icon name="hero-briefcase" class="size-5" />
                Project Information
              </h2>
              
              <div class="space-y-4 mt-4">
                <div class="flex items-center gap-3">
                  <div class="avatar avatar-placeholder">
                    <div class="text-white w-8 rounded-full" style={"background-color: #{@time_entry.project.color || "#666"}"}>
                      <span class="text-xs">{String.slice(@time_entry.project.name, 0..1) |> String.upcase}</span>
                    </div>
                  </div>
                  <div>
                    <div class="font-semibold text-lg">{@time_entry.project.name}</div>
                    <div class="text-sm opacity-70">{@time_entry.project.client.name}</div>
                  </div>
                </div>
                
                <div class="divider my-2"></div>
                
                <div>
                  <div class="text-sm opacity-70 mb-2">Description</div>
                  <div class="text-base">
                    <%= if @time_entry.description && String.trim(@time_entry.description) != "" do %>
                      {@time_entry.description}
                    <% else %>
                      <span class="italic opacity-50">No description provided</span>
                    <% end %>
                  </div>
                </div>
              </div>
            </div>
          </div>
          
          <!-- Time Details Card -->
          <div class="card bg-base-100 shadow-lg">
            <div class="card-body">
              <h2 class="card-title text-lg">
                <.icon name="hero-clock" class="size-5" />
                Time Details
              </h2>
              
              <div class="space-y-4 mt-4">
                <div class="stat">
                  <div class="stat-title">Duration</div>
                  <div class="stat-value text-primary text-2xl">
                    {format_duration(@time_entry.duration_minutes)}
                  </div>
                </div>
                
                <div class="divider my-2"></div>
                
                <div>
                  <div class="text-sm opacity-70 mb-2">Time Range</div>
                  <div class="badge badge-outline badge-lg">
                    <%= if @time_entry.start_time && @time_entry.end_time do %>
                      {format_time(@time_entry.start_time)} - {format_time(@time_entry.end_time)}
                    <% else %>
                      Manual entry
                    <% end %>
                  </div>
                </div>
                
                <div>
                  <div class="text-sm opacity-70 mb-2">Billable Status</div>
                  <%= if @time_entry.billable do %>
                    <div class="badge badge-success gap-2">
                      <.icon name="hero-check-circle" class="size-4" />
                      Billable
                    </div>
                  <% else %>
                    <div class="badge badge-ghost gap-2">
                      <.icon name="hero-x-circle" class="size-4" />
                      Non-billable
                    </div>
                  <% end %>
                </div>
                
                <%= if @time_entry.pause_duration_minutes && @time_entry.pause_duration_minutes > 0 do %>
                  <div>
                    <div class="text-sm opacity-70 mb-2">Pause Duration</div>
                    <div class="badge badge-warning gap-2">
                      <.icon name="hero-pause-circle" class="size-4" />
                      {format_duration(@time_entry.pause_duration_minutes)}
                    </div>
                    <div class="text-xs opacity-60 mt-1">Lunch breaks or other pauses</div>
                  </div>
                <% end %>
              </div>
            </div>
          </div>
        </div>
      </div>
    </Layouts.app>
    """
  end
  
  defp format_duration(nil), do: "0:00"
  defp format_duration(minutes) do
    hours = div(minutes, 60)
    mins = rem(minutes, 60)
    "#{hours}:#{String.pad_leading(to_string(mins), 2, "0")}"
  end
  
  defp format_time(nil), do: "-"
  defp format_time(time) do
    case time do
      %Time{} = t ->
        hour = t.hour
        minute = t.minute
        "#{String.pad_leading(to_string(hour), 2, "0")}:#{String.pad_leading(to_string(minute), 2, "0")}"
      
      _ ->
        # Fallback for other time formats
        to_string(time)
    end
  end

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    user = socket.assigns.current_user
    time_entry = Tracking.get_time_entry!(user, id)
    
    {:ok,
     socket
     |> assign(:page_title, "Show Time entry")
     |> assign(:time_entry, time_entry)}
  end
end
