defmodule JikanWeb.ProjectLive.Index do
  use JikanWeb, :live_view

  alias Jikan.Tracking

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <.header>
        Projects
        <:actions>
          <.button variant="primary" navigate={~p"/projects/new"}>
            <.icon name="hero-plus" /> New Project
          </.button>
        </:actions>
      </.header>

      <.table
        id="projects"
        rows={@streams.projects}
        row_click={fn {_id, project} -> JS.navigate(~p"/projects/#{project}") end}
      >
        <:col :let={{_id, project}} label="Name">{project.name}</:col>
        <:col :let={{_id, project}} label="Description">{project.description}</:col>
        <:col :let={{_id, project}} label="Color">{project.color}</:col>
        <:col :let={{_id, project}} label="Archived">{project.archived}</:col>
        <:action :let={{_id, project}}>
          <div class="sr-only">
            <.link navigate={~p"/projects/#{project}"}>Show</.link>
          </div>
          <.link navigate={~p"/projects/#{project}/edit"}>Edit</.link>
        </:action>
        <:action :let={{id, project}}>
          <.link
            phx-click={JS.push("delete", value: %{id: project.id}) |> hide("##{id}")}
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
     |> assign(:page_title, "Listing Projects")
     |> stream(:projects, list_projects(user))}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    user = socket.assigns.current_user
    project = Tracking.get_project!(user, id)
    {:ok, _} = Tracking.delete_project(project)

    {:noreply, stream_delete(socket, :projects, project)}
  end

  defp list_projects(user) do
    Tracking.list_projects(user)
  end
end
