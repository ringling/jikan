defmodule JikanWeb.TimeEntryLive.Index do
  use JikanWeb, :live_view

  alias Jikan.Tracking

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <.header>
        Time Entries
        <:actions>
          <.button variant="primary" navigate={~p"/time-entries/new"}>
            <.icon name="hero-plus" /> New Entry
          </.button>
        </:actions>
      </.header>

      <.table
        id="time_entries"
        rows={@streams.time_entries}
        row_click={fn {_id, time_entry} -> JS.navigate(~p"/time-entries/#{time_entry}") end}
      >
        <:col :let={{_id, time_entry}} label="Description">{time_entry.description}</:col>
        <:col :let={{_id, time_entry}} label="Date">{time_entry.date}</:col>
        <:col :let={{_id, time_entry}} label="Start time">{time_entry.start_time}</:col>
        <:col :let={{_id, time_entry}} label="End time">{time_entry.end_time}</:col>
        <:col :let={{_id, time_entry}} label="Duration minutes">{time_entry.duration_minutes}</:col>
        <:col :let={{_id, time_entry}} label="Billable">{time_entry.billable}</:col>
        <:action :let={{_id, time_entry}}>
          <div class="sr-only">
            <.link navigate={~p"/time-entries/#{time_entry}"}>Show</.link>
          </div>
          <.link navigate={~p"/time-entries/#{time_entry}/edit"}>Edit</.link>
        </:action>
        <:action :let={{id, time_entry}}>
          <.link
            phx-click={JS.push("delete", value: %{id: time_entry.id}) |> hide("##{id}")}
            data-confirm="Are you sure?"
          >
            Delete
          </.link>
        </:action>
      </.table>
    </Layouts.app>
    """
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
