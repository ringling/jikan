defmodule JikanWeb.TimeEntryLive.Index do
  use JikanWeb, :live_view

  alias Jikan.Tracking

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <div>
        <h1 class="text-3xl font-bold text-gray-900 mb-8 flex items-center gap-2">
          <.icon name="hero-clock" class="size-8" />
          Time Entries
        </h1>
        
        <div class="bg-white rounded-lg shadow">
          <div class="p-6 border-b border-gray-200">
            <div class="flex items-center justify-between">
              <p class="text-gray-600">Track and manage your time entries</p>
              <.button variant="primary" navigate={~p"/time-entries/new"} class="flex items-center gap-2">
                <.icon name="hero-plus" class="size-5" />
                New Entry
              </.button>
            </div>
          </div>
          
          <div class="overflow-x-auto">
            <.table
              id="time_entries"
              rows={@streams.time_entries}
              row_click={fn {_id, time_entry} -> JS.navigate(~p"/time-entries/#{time_entry}") end}
            >
              <:col :let={{_id, time_entry}} label="Project">
                <div class="flex items-center gap-2">
                  <span 
                    class="inline-block w-3 h-3 rounded-full"
                    style={"background-color: #{time_entry.project.color || "#666"}"}
                  ></span>
                  <span class="font-medium">{time_entry.project.name}</span>
                </div>
              </:col>
              <:col :let={{_id, time_entry}} label="Description">
                <span class="text-gray-900">{time_entry.description || "-"}</span>
              </:col>
              <:col :let={{_id, time_entry}} label="Date">
                <span class="text-gray-600">{Calendar.strftime(time_entry.date, "%b %d, %Y")}</span>
              </:col>
              <:col :let={{_id, time_entry}} label="Duration">
                <span class="font-medium text-gray-900">
                  {format_duration(time_entry.duration_minutes)}
                </span>
              </:col>
              <:col :let={{_id, time_entry}} label="Billable">
                <%= if time_entry.billable do %>
                  <span class="text-green-600">
                    <.icon name="hero-check-circle" class="size-5" />
                  </span>
                <% else %>
                  <span class="text-gray-400">
                    <.icon name="hero-x-circle" class="size-5" />
                  </span>
                <% end %>
              </:col>
              <:action :let={{_id, time_entry}}>
                <div class="flex items-center gap-2">
                  <.link 
                    navigate={~p"/time-entries/#{time_entry}/edit"}
                    class="text-blue-600 hover:text-blue-800"
                  >
                    <.icon name="hero-pencil-square" class="size-4" />
                  </.link>
                  <.link
                    phx-click={JS.push("delete", value: %{id: time_entry.id}) |> hide("#time_entries-#{time_entry.id}")}
                    data-confirm="Are you sure?"
                    class="text-red-600 hover:text-red-800"
                  >
                    <.icon name="hero-trash" class="size-4" />
                  </.link>
                </div>
              </:action>
            </.table>
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

  @impl true
  def mount(_params, _session, socket) do
    user = socket.assigns.current_user
    
    {:ok,
     socket
     |> assign(:page_title, "Listing Time entries")
     |> stream(:time_entries, list_time_entries(user))}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    user = socket.assigns.current_user
    time_entry = Tracking.get_time_entry!(user, id)
    {:ok, _} = Tracking.delete_time_entry(time_entry)

    {:noreply, stream_delete(socket, :time_entries, time_entry)}
  end

  defp list_time_entries(user) do
    Tracking.list_time_entries(user)
  end
end
