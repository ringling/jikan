defmodule JikanWeb.TimeEntryLive.Show do
  use JikanWeb, :live_view

  alias Jikan.Tracking

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <.header>
        Time entry {@time_entry.id}
        <:subtitle>This is a time_entry record from your database.</:subtitle>
        <:actions>
          <.button navigate={~p"/time-entries"}>
            <.icon name="hero-arrow-left" />
          </.button>
          <.button variant="primary" navigate={~p"/time-entries/#{@time_entry}/edit?return_to=show"}>
            <.icon name="hero-pencil-square" /> Edit time_entry
          </.button>
        </:actions>
      </.header>

      <.list>
        <:item title="Description">{@time_entry.description}</:item>
        <:item title="Date">{@time_entry.date}</:item>
        <:item title="Start time">{@time_entry.start_time}</:item>
        <:item title="End time">{@time_entry.end_time}</:item>
        <:item title="Duration minutes">{@time_entry.duration_minutes}</:item>
        <:item title="Billable">{@time_entry.billable}</:item>
      </.list>
    </Layouts.app>
    """
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
