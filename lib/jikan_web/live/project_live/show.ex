defmodule JikanWeb.ProjectLive.Show do
  use JikanWeb, :live_view

  alias Jikan.Tracking

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <.header>
        {@project.name}
        <:subtitle>{@project.description}</:subtitle>
        <:actions>
          <.button navigate={~p"/projects"}>
            <.icon name="hero-arrow-left" />
          </.button>
          <.button variant="primary" navigate={~p"/projects/#{@project}/edit?return_to=show"}>
            <.icon name="hero-pencil-square" /> Edit
          </.button>
        </:actions>
      </.header>

      <.list>
        <:item title="Name">{@project.name}</:item>
        <:item title="Description">{@project.description}</:item>
        <:item title="Color">{@project.color}</:item>
        <:item title="Archived">{@project.archived}</:item>
      </.list>
    </Layouts.app>
    """
  end

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    user = socket.assigns.current_user
    project = Tracking.get_project!(user, id)
    
    {:ok,
     socket
     |> assign(:page_title, "Show Project")
     |> assign(:project, project)}
  end
end
