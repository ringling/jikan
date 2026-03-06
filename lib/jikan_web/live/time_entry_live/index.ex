defmodule JikanWeb.TimeEntryLive.Index do
  use JikanWeb, :live_view

  alias Jikan.Tracking

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <div class="p-6">
        <.header>
          <.icon name="hero-clock" class="size-8 inline" /> Time Entries
          <:subtitle>Track and manage your time entries</:subtitle>
          <:actions>
            <.button variant="primary" navigate={~p"/time-entries/new"} class="gap-2">
              <.icon name="hero-plus" class="size-5" />
              New Entry
            </.button>
          </:actions>
        </.header>
        
        <div class="card bg-base-100 shadow-lg">
          <div class="card-body p-0">
            <div class="overflow-x-auto">
              <.table
                id="time_entries"
                rows={@streams.time_entries}
                row_click={fn {_id, time_entry} -> JS.navigate(~p"/time-entries/#{time_entry}") end}
              >
                <:col :let={{_id, time_entry}} label="Project">
                  <div class="flex items-center gap-3">
                    <div class="avatar avatar-placeholder">
                      <div class="text-white w-8 rounded-full" style={"background-color: #{time_entry.project.color || "#666"}"}>
                        <span class="text-xs">{String.slice(time_entry.project.name, 0..1) |> String.upcase}</span>
                      </div>
                    </div>
                    <div>
                      <div class="font-semibold">{time_entry.project.name}</div>
                      <div class="text-sm opacity-70">{time_entry.project.client.name}</div>
                    </div>
                  </div>
                </:col>
                <:col :let={{_id, time_entry}} label="Description" class="hidden md:table-cell">
                  <span class="text-base-content">{time_entry.description || "-"}</span>
                </:col>
                <:col :let={{_id, time_entry}} label="Date">
                  <div class="badge badge-outline whitespace-nowrap">
                    {Calendar.strftime(time_entry.date, "%b %d, %Y")}
                  </div>
                </:col>
                <:col :let={{_id, time_entry}} label="Duration">
                  <div class="flex flex-col items-start">
                    <div class="badge badge-primary">
                      {format_duration(time_entry.duration_minutes)}
                    </div>
                    <%= if time_entry.pause_duration_minutes && time_entry.pause_duration_minutes > 0 do %>
                      <div class="badge badge-warning badge-sm mt-1">
                        <.icon name="hero-pause-circle" class="size-3 mr-1" />
                        {format_duration(time_entry.pause_duration_minutes)}
                      </div>
                    <% end %>
                  </div>
                </:col>
                <:col :let={{_id, time_entry}} label="Billable">
                  <%= if time_entry.billable do %>
                    <div class="badge badge-success gap-1">
                      <.icon name="hero-check-circle" class="size-4" />
                      Billable
                    </div>
                  <% else %>
                    <div class="badge badge-ghost gap-1">
                      <.icon name="hero-x-circle" class="size-4" />
                      Non-billable
                    </div>
                  <% end %>
                </:col>
                <:action :let={{_id, time_entry}}>
                  <div class="dropdown dropdown-end">
                    <div tabindex="0" role="button" class="btn btn-ghost btn-sm">
                      <.icon name="hero-ellipsis-vertical" class="size-4" />
                    </div>
                    <ul tabindex="0" class="dropdown-content menu bg-base-100 rounded-box z-[1] w-52 p-2 shadow">
                      <li>
                        <.link navigate={~p"/time-entries/#{time_entry}/edit"} class="flex items-center gap-2">
                          <.icon name="hero-pencil-square" class="size-4" />
                          Edit
                        </.link>
                      </li>
                      <li>
                        <.link
                          phx-click={JS.push("delete", value: %{id: time_entry.id}) |> hide("#time_entries-#{time_entry.id}")}
                          data-confirm="Are you sure?"
                          class="flex items-center gap-2 text-error"
                        >
                          <.icon name="hero-trash" class="size-4" />
                          Delete
                        </.link>
                      </li>
                    </ul>
                  </div>
                </:action>
              </.table>
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
