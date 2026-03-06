defmodule JikanWeb.ProjectLive.Show do
  use JikanWeb, :live_view

  alias Jikan.Tracking

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <div class="p-1">
        <div class="breadcrumbs text-sm mb-6">
          <ul>
            <li>
              <.link navigate={~p"/projects"} class="btn btn-ghost btn-sm gap-2">
                <.icon name="hero-arrow-left" class="size-4" />
                Projects
              </.link>
            </li>
            <li>Project Details</li>
          </ul>
        </div>
        
        <.header>
          <div class="flex items-center gap-3">
            <div class="avatar avatar-placeholder">
              <div class="text-white w-12 rounded-full" style={"background-color: #{@project.color || "#666"}"}>
                <span class="text-lg">{String.slice(@project.name, 0..1) |> String.upcase}</span>
              </div>
            </div>
            <div>
              <.icon name="hero-folder" class="size-8 inline" /> {@project.name}
            </div>
          </div>
          <:subtitle>
            {@project.description || "No description provided"}
          </:subtitle>
          <:actions>
            <.button variant="primary" navigate={~p"/projects/#{@project}/edit?return_to=show"} class="gap-2">
              <.icon name="hero-pencil-square" class="size-5" />
              Edit Project
            </.button>
          </:actions>
        </.header>
        
        <div class="grid grid-cols-1 lg:grid-cols-2 gap-6">
          <!-- Project Details Card -->
          <div class="card bg-base-100 shadow-lg">
            <div class="card-body">
              <h2 class="card-title text-lg">
                <.icon name="hero-information-circle" class="size-5" />
                Project Information
              </h2>
              
              <div class="space-y-4 mt-4">
                <div>
                  <div class="text-sm opacity-70 mb-2">Client</div>
                  <div class="flex items-center gap-3">
                    <div class="avatar avatar-placeholder">
                      <div class="bg-primary text-primary-content w-8 rounded-full">
                        <span class="text-xs">{String.slice(@project.client.name, 0..1) |> String.upcase}</span>
                      </div>
                    </div>
                    <div>
                      <div class="font-semibold">{@project.client.name}</div>
                      <%= if @project.client.contact_email do %>
                        <div class="text-sm opacity-70">{@project.client.contact_email}</div>
                      <% end %>
                    </div>
                  </div>
                </div>
                
                <div class="divider my-2"></div>
                
                <div>
                  <div class="text-sm opacity-70 mb-2">Status</div>
                  <%= if @project.archived do %>
                    <div class="badge badge-ghost gap-1">
                      <.icon name="hero-archive-box" class="size-3" />
                      Archived
                    </div>
                  <% else %>
                    <div class="badge badge-success gap-1">
                      <.icon name="hero-check-circle" class="size-3" />
                      Active
                    </div>
                  <% end %>
                </div>
                
                <div>
                  <div class="text-sm opacity-70 mb-2">Project Color</div>
                  <div class="flex items-center gap-3">
                    <div class="w-8 h-8 rounded border-2 border-base-300" style={"background-color: #{@project.color || "#666"}"}></div>
                    <div class="font-mono text-sm">{@project.color || "#666666"}</div>
                  </div>
                </div>
              </div>
            </div>
          </div>
          
          <!-- Quick Actions Card -->
          <div class="card bg-base-100 shadow-lg">
            <div class="card-body">
              <h2 class="card-title text-lg">
                <.icon name="hero-bolt" class="size-5" />
                Quick Actions
              </h2>
              
              <div class="space-y-3 mt-4">
                <.button variant="outline" navigate={~p"/time-entries/new?project_id=#{@project.id}"} class="w-full gap-2">
                  <.icon name="hero-plus" class="size-4" />
                  Add Time Entry for This Project
                </.button>
                
                <.button variant="ghost" navigate={~p"/time-entries?project_id=#{@project.id}"} class="w-full gap-2">
                  <.icon name="hero-clock" class="size-4" />
                  View All Time Entries
                </.button>
                
                <div class="divider my-2"></div>
                
                <.button variant="ghost" navigate={~p"/projects/#{@project}/edit"} class="w-full gap-2">
                  <.icon name="hero-pencil-square" class="size-4" />
                  Edit Project Details
                </.button>
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
