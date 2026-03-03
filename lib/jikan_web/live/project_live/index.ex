defmodule JikanWeb.ProjectLive.Index do
  use JikanWeb, :live_view

  alias Jikan.Tracking

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <div>
        <h1 class="text-3xl font-bold text-gray-900 mb-8 flex items-center gap-2">
          <.icon name="hero-folder" class="size-8" />
          Projects
        </h1>
        
        <div class="bg-white rounded-lg shadow">
          <div class="p-6 border-b border-gray-200">
            <div class="flex items-center justify-between">
              <p class="text-gray-600">Manage your projects and track their status</p>
              <.button variant="primary" navigate={~p"/projects/new"} class="flex items-center gap-2">
                <.icon name="hero-plus" class="size-5" />
                New Project
              </.button>
            </div>
          </div>
          
          <div class="overflow-x-auto">
            <.table
              id="projects"
              rows={@streams.projects}
              row_click={fn {_id, project} -> JS.navigate(~p"/projects/#{project}") end}
            >
              <:col :let={{_id, project}} label="Name">
                <div class="flex items-center gap-2">
                  <span 
                    class="inline-block w-3 h-3 rounded-full"
                    style={"background-color: #{project.color || "#666"}"}
                  ></span>
                  <span class="font-medium text-gray-900">{project.name}</span>
                </div>
              </:col>
              <:col :let={{_id, project}} label="Client">
                <span class="text-gray-600">{project.client.name}</span>
              </:col>
              <:col :let={{_id, project}} label="Description">
                <span class="text-gray-600">{project.description || "-"}</span>
              </:col>
              <:col :let={{_id, project}} label="Status">
                <%= if project.archived do %>
                  <span class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-gray-100 text-gray-800">
                    Archived
                  </span>
                <% else %>
                  <span class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-green-100 text-green-800">
                    Active
                  </span>
                <% end %>
              </:col>
              <:action :let={{_id, project}}>
                <div class="flex items-center gap-2">
                  <.link 
                    navigate={~p"/projects/#{project}/edit"}
                    class="text-blue-600 hover:text-blue-800"
                  >
                    <.icon name="hero-pencil-square" class="size-4" />
                  </.link>
                  <.link
                    phx-click={JS.push("delete", value: %{id: project.id}) |> hide("#projects-#{project.id}")}
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
