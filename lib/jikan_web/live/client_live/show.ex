defmodule JikanWeb.ClientLive.Show do
  use JikanWeb, :live_view

  alias Jikan.Tracking

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <div>
        <div class="mb-8">
          <.link navigate={~p"/clients"} class="text-blue-600 hover:text-blue-800 flex items-center gap-1 mb-4">
            <.icon name="hero-arrow-left" class="size-4" />
            Back to Clients
          </.link>
          
          <div class="flex items-start justify-between">
            <div>
              <h1 class="text-3xl font-bold text-gray-900 flex items-center gap-2">
                <.icon name="hero-building-office" class="size-8" />
                {@client.name}
              </h1>
              <p class="text-gray-600 mt-2">
                Client Information
              </p>
            </div>
            
            <.button variant="primary" navigate={~p"/clients/#{@client}/edit?return_to=show"} class="flex items-center gap-2">
              <.icon name="hero-pencil-square" class="size-5" />
              Edit Client
            </.button>
          </div>
        </div>
        
        <div class="bg-white rounded-lg shadow">
          <div class="p-6 space-y-6">
            <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
              <div>
                <h3 class="text-sm font-medium text-gray-500 mb-1">Company Name</h3>
                <p class="text-lg font-medium text-gray-900">{@client.name}</p>
              </div>
              
              <div>
                <h3 class="text-sm font-medium text-gray-500 mb-1">Contact Email</h3>
                <div class="flex items-center gap-2">
                  <.icon name="hero-envelope" class="size-5 text-gray-400" />
                  <%= if @client.contact_email do %>
                    <a href={"mailto:#{@client.contact_email}"} class="text-lg text-blue-600 hover:text-blue-800">
                      {@client.contact_email}
                    </a>
                  <% else %>
                    <p class="text-lg text-gray-900">No email provided</p>
                  <% end %>
                </div>
              </div>
              
              <div>
                <h3 class="text-sm font-medium text-gray-500 mb-1">Status</h3>
                <div class="flex items-center gap-2">
                  <%= if @client.active do %>
                    <.icon name="hero-check-circle" class="size-5 text-green-600" />
                    <span class="inline-flex items-center px-3 py-1 rounded-full text-sm font-medium bg-green-100 text-green-800">
                      Active
                    </span>
                  <% else %>
                    <.icon name="hero-x-circle" class="size-5 text-gray-400" />
                    <span class="inline-flex items-center px-3 py-1 rounded-full text-sm font-medium bg-gray-100 text-gray-800">
                      Inactive
                    </span>
                  <% end %>
                </div>
              </div>
              
              <div>
                <h3 class="text-sm font-medium text-gray-500 mb-1">Projects</h3>
                <div class="flex items-center gap-2">
                  <.icon name="hero-folder" class="size-5 text-gray-400" />
                  <p class="text-lg text-gray-900">
                    {length(@client.projects || [])} active projects
                  </p>
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
