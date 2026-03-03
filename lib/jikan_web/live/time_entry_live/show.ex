defmodule JikanWeb.TimeEntryLive.Show do
  use JikanWeb, :live_view

  alias Jikan.Tracking

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <div>
        <div class="mb-8">
          <.link navigate={~p"/time-entries"} class="text-blue-600 hover:text-blue-800 flex items-center gap-1 mb-4">
            <.icon name="hero-arrow-left" class="size-4" />
            Back to Time Entries
          </.link>
          
          <div class="flex items-start justify-between">
            <div>
              <h1 class="text-3xl font-bold text-gray-900 flex items-center gap-2">
                <.icon name="hero-clock" class="size-8" />
                Time Entry Details
              </h1>
              <p class="text-gray-600 mt-2">
                {Calendar.strftime(@time_entry.date, "%B %d, %Y")}
              </p>
            </div>
            
            <.button variant="primary" navigate={~p"/time-entries/#{@time_entry}/edit?return_to=show"} class="flex items-center gap-2">
              <.icon name="hero-pencil-square" class="size-5" />
              Edit Entry
            </.button>
          </div>
        </div>
        
        <div class="bg-white rounded-lg shadow">
          <div class="p-6 space-y-6">
            <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
              <div>
                <h3 class="text-sm font-medium text-gray-500 mb-1">Project</h3>
                <div class="flex items-center gap-2">
                  <span 
                    class="inline-block w-3 h-3 rounded-full"
                    style={"background-color: #{@time_entry.project.color || "#666"}"}
                  ></span>
                  <p class="text-lg font-medium text-gray-900">{@time_entry.project.name}</p>
                </div>
              </div>
              
              <div>
                <h3 class="text-sm font-medium text-gray-500 mb-1">Client</h3>
                <p class="text-lg text-gray-900">{@time_entry.project.client.name}</p>
              </div>
              
              <div>
                <h3 class="text-sm font-medium text-gray-500 mb-1">Description</h3>
                <p class="text-lg text-gray-900">{@time_entry.description || "No description"}</p>
              </div>
              
              <div>
                <h3 class="text-sm font-medium text-gray-500 mb-1">Duration</h3>
                <p class="text-lg font-medium text-gray-900">
                  {format_duration(@time_entry.duration_minutes)}
                </p>
              </div>
              
              <div>
                <h3 class="text-sm font-medium text-gray-500 mb-1">Time Range</h3>
                <p class="text-lg text-gray-900">
                  <%= if @time_entry.start_time && @time_entry.end_time do %>
                    {format_time(@time_entry.start_time)} - {format_time(@time_entry.end_time)}
                  <% else %>
                    Manual entry
                  <% end %>
                </p>
              </div>
              
              <div>
                <h3 class="text-sm font-medium text-gray-500 mb-1">Billable Status</h3>
                <div class="flex items-center gap-2">
                  <%= if @time_entry.billable do %>
                    <.icon name="hero-check-circle" class="size-5 text-green-600" />
                    <span class="text-lg text-gray-900">Billable</span>
                  <% else %>
                    <.icon name="hero-x-circle" class="size-5 text-gray-400" />
                    <span class="text-lg text-gray-900">Non-billable</span>
                  <% end %>
                </div>
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
