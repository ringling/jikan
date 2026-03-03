defmodule JikanWeb.ClientLive.Show do
  use JikanWeb, :live_view

  alias Jikan.Tracking

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <.header>
        {@client.name}
        <:subtitle>{@client.contact_email}</:subtitle>
        <:actions>
          <.button navigate={~p"/clients"}>
            <.icon name="hero-arrow-left" />
          </.button>
          <.button variant="primary" navigate={~p"/clients/#{@client}/edit?return_to=show"}>
            <.icon name="hero-pencil-square" /> Edit
          </.button>
        </:actions>
      </.header>

      <.list>
        <:item title="Name">{@client.name}</:item>
        <:item title="Contact email">{@client.contact_email}</:item>
        <:item title="Active">{@client.active}</:item>
      </.list>
    </Layouts.app>
    """
  end

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    user = socket.assigns.current_user
    client = Tracking.get_client!(user, id)
    
    {:ok,
     socket
     |> assign(:page_title, "Show Client")
     |> assign(:client, client)}
  end
end
