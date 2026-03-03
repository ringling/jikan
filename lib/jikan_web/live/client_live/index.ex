defmodule JikanWeb.ClientLive.Index do
  use JikanWeb, :live_view

  alias Jikan.Tracking

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <div>
        <h1 class="text-3xl font-bold text-gray-900 mb-8 flex items-center gap-2">
          <.icon name="hero-user-group" class="size-8" />
          Clients
        </h1>
        
        <div class="bg-white rounded-lg shadow">
          <div class="p-6 border-b border-gray-200">
            <div class="flex items-center justify-between">
              <p class="text-gray-600">Manage your client information</p>
              <.button variant="primary" navigate={~p"/clients/new"} class="flex items-center gap-2">
                <.icon name="hero-plus" class="size-5" />
                New Client
              </.button>
            </div>
          </div>
          
          <div class="overflow-x-auto">
            <.table
              id="clients"
              rows={@streams.clients}
              row_click={fn {_id, client} -> JS.navigate(~p"/clients/#{client}") end}
            >
              <:col :let={{_id, client}} label="Name">
                <div class="flex items-center gap-2">
                  <.icon name="hero-building-office" class="size-5 text-gray-400" />
                  <span class="font-medium text-gray-900">{client.name}</span>
                </div>
              </:col>
              <:col :let={{_id, client}} label="Contact Email">
                <div class="flex items-center gap-2">
                  <.icon name="hero-envelope" class="size-4 text-gray-400" />
                  <a href={"mailto:#{client.contact_email}"} class="text-blue-600 hover:text-blue-800">
                    {client.contact_email || "-"}
                  </a>
                </div>
              </:col>
              <:col :let={{_id, client}} label="Projects">
                <span class="text-gray-600">
                  {length(client.projects || [])} projects
                </span>
              </:col>
              <:col :let={{_id, client}} label="Status">
                <%= if client.active do %>
                  <span class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-green-100 text-green-800">
                    Active
                  </span>
                <% else %>
                  <span class="inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium bg-gray-100 text-gray-800">
                    Inactive
                  </span>
                <% end %>
              </:col>
              <:action :let={{_id, client}}>
                <div class="flex items-center gap-2">
                  <.link 
                    navigate={~p"/clients/#{client}/edit"}
                    class="text-blue-600 hover:text-blue-800"
                  >
                    <.icon name="hero-pencil-square" class="size-4" />
                  </.link>
                  <.link
                    phx-click={JS.push("delete", value: %{id: client.id}) |> hide("#clients-#{client.id}")}
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
     |> assign(:page_title, "Listing Clients")
     |> stream(:clients, list_clients(user))}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    user = socket.assigns.current_user
    client = Tracking.get_client!(user, id)
    {:ok, _} = Tracking.delete_client(client)

    {:noreply, stream_delete(socket, :clients, client)}
  end

  defp list_clients(user) do
    Tracking.list_clients(user)
  end
end
