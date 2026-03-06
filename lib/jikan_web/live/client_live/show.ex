defmodule JikanWeb.ClientLive.Show do
  use JikanWeb, :live_view

  alias Jikan.Tracking

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <div class="p-6 max-w-4xl mx-auto">
        <div class="breadcrumbs text-sm mb-6">
          <ul>
            <li>
              <.link navigate={~p"/clients"} class="btn btn-ghost btn-sm gap-2">
                <.icon name="hero-arrow-left" class="size-4" />
                Clients
              </.link>
            </li>
            <li>Client Details</li>
          </ul>
        </div>
        
        <.header>
          <div class="flex items-center gap-3">
            <div class="avatar avatar-placeholder">
              <div class="bg-primary text-primary-content w-12 rounded-full">
                <span class="text-lg">{String.slice(@client.name, 0..1) |> String.upcase}</span>
              </div>
            </div>
            <div>
              <.icon name="hero-building-office" class="size-8 inline" /> {@client.name}
            </div>
          </div>
          <:subtitle>
            Client information and project details
          </:subtitle>
          <:actions>
            <.button variant="primary" navigate={~p"/clients/#{@client}/edit?return_to=show"} class="gap-2">
              <.icon name="hero-pencil-square" class="size-5" />
              Edit Client
            </.button>
          </:actions>
        </.header>
        
        <div class="grid grid-cols-1 lg:grid-cols-2 gap-6">
          <!-- Client Details Card -->
          <div class="card bg-base-100 shadow-lg">
            <div class="card-body">
              <h2 class="card-title text-lg">
                <.icon name="hero-information-circle" class="size-5" />
                Contact Information
              </h2>
              
              <div class="space-y-4 mt-4">
                <div>
                  <div class="text-sm opacity-70 mb-2">Company Name</div>
                  <div class="text-lg font-semibold">{@client.name}</div>
                </div>
                
                <div class="divider my-2"></div>
                
                <div>
                  <div class="text-sm opacity-70 mb-2">Contact Email</div>
                  <%= if @client.contact_email do %>
                    <div class="flex items-center gap-2">
                      <.icon name="hero-envelope" class="size-4" />
                      <a href={"mailto:#{@client.contact_email}"} class="link link-primary">
                        {@client.contact_email}
                      </a>
                    </div>
                  <% else %>
                    <div class="text-base opacity-60 italic">No email provided</div>
                  <% end %>
                </div>
                
                <div>
                  <div class="text-sm opacity-70 mb-2">Status</div>
                  <%= if @client.active do %>
                    <div class="badge badge-success gap-1">
                      <.icon name="hero-check-circle" class="size-3" />
                      Active
                    </div>
                  <% else %>
                    <div class="badge badge-ghost gap-1">
                      <.icon name="hero-pause-circle" class="size-3" />
                      Inactive
                    </div>
                  <% end %>
                </div>
              </div>
            </div>
          </div>
          
          <!-- Projects & Quick Actions Card -->
          <div class="card bg-base-100 shadow-lg">
            <div class="card-body">
              <h2 class="card-title text-lg">
                <.icon name="hero-folder" class="size-5" />
                Projects & Actions
              </h2>
              
              <div class="space-y-4 mt-4">
                <div class="stat">
                  <div class="stat-title">Active Projects</div>
                  <div class="stat-value text-primary text-2xl">
                    {length(@client.projects || [])}
                  </div>
                  <div class="stat-desc">Projects for this client</div>
                </div>
                
                <div class="divider my-2"></div>
                
                <div class="space-y-3">
                  <.button variant="outline" navigate={~p"/projects/new?client_id=#{@client.id}"} class="w-full gap-2">
                    <.icon name="hero-plus" class="size-4" />
                    Add New Project
                  </.button>
                  
                  <.button variant="ghost" navigate={~p"/projects?client_id=#{@client.id}"} class="w-full gap-2">
                    <.icon name="hero-folder" class="size-4" />
                    View All Projects
                  </.button>
                  
                  <.button variant="ghost" navigate={~p"/time-entries?client_id=#{@client.id}"} class="w-full gap-2">
                    <.icon name="hero-clock" class="size-4" />
                    View Time Entries
                  </.button>
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
    client = Tracking.get_client!(user, id)
    
    {:ok,
     socket
     |> assign(:page_title, "Show Client")
     |> assign(:client, client)}
  end
end
