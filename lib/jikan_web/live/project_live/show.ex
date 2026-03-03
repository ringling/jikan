defmodule JikanWeb.ProjectLive.Show do
  use JikanWeb, :live_view

  alias Jikan.Tracking

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <div>
        <div class="mb-8">
          <.link navigate={~p"/projects"} class="text-blue-600 hover:text-blue-800 flex items-center gap-1 mb-4">
            <.icon name="hero-arrow-left" class="size-4" />
            Back to Projects
          </.link>
          
          <div class="flex items-start justify-between">
            <div class="flex items-center gap-4">
              <span 
                class="inline-block w-12 h-12 rounded-lg"
                style={"background-color: #{@project.color || "#666"}"}
              ></span>
              <div>
                <h1 class="text-3xl font-bold text-gray-900">
                  {@project.name}
                </h1>
                <p class="text-gray-600 mt-1">
                  {@project.description || "No description"}
                </p>
              </div>
            </div>
            
            <.button variant="primary" navigate={~p"/projects/#{@project}/edit?return_to=show"} class="flex items-center gap-2">
              <.icon name="hero-pencil-square" class="size-5" />
              Edit Project
            </.button>
          </div>
        </div>
        
        <div class="bg-white rounded-lg shadow">
          <div class="p-6 space-y-6">
            <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
              <div>
                <h3 class="text-sm font-medium text-gray-500 mb-1">Client</h3>
                <div class="flex items-center gap-2">
                  <.icon name="hero-building-office" class="size-5 text-gray-400" />
                  <p class="text-lg text-gray-900">{@project.client.name}</p>
                </div>
              </div>
              
              <div>
                <h3 class="text-sm font-medium text-gray-500 mb-1">Status</h3>
                <div class="flex items-center gap-2">
                  <%= if @project.archived do %>
                    <.icon name="hero-archive-box" class="size-5 text-gray-400" />
                    <span class="inline-flex items-center px-3 py-1 rounded-full text-sm font-medium bg-gray-100 text-gray-800">
                      Archived
                    </span>
                  <% else %>
                    <.icon name="hero-check-circle" class="size-5 text-green-600" />
                    <span class="inline-flex items-center px-3 py-1 rounded-full text-sm font-medium bg-green-100 text-green-800">
                      Active
                    </span>
                  <% end %>
                </div>
              </div>
              
              <div>
                <h3 class="text-sm font-medium text-gray-500 mb-1">Color</h3>
                <div class="flex items-center gap-2">
                  <span 
                    class="inline-block w-6 h-6 rounded border border-gray-300"
                    style={"background-color: #{@project.color || "#666"}"}
                  ></span>
                  <p class="text-lg text-gray-900">{@project.color || "Default"}</p>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
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
