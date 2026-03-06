defmodule JikanWeb.ClientLive.Index do
  use JikanWeb, :live_view

  alias Jikan.Tracking

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <div class="p-6">
        <.header>
          <.icon name="hero-user-group" class="size-8 inline" /> Clients
          <:subtitle>Manage your client information and relationships</:subtitle>
          <:actions>
            <.button variant="primary" navigate={~p"/clients/new"} class="gap-2">
              <.icon name="hero-plus" class="size-5" />
              New Client
            </.button>
          </:actions>
        </.header>
        
        <div class="card bg-base-100 shadow-lg">
          <div class="card-body p-0">
            <div class="overflow-x-auto">
              <.table
                id="clients"
                rows={@streams.clients}
                row_click={fn {_id, client} -> JS.navigate(~p"/clients/#{client}") end}
              >
                <:col :let={{_id, client}} label="Client">
                  <div class="flex items-center gap-3">
                    <div class="avatar avatar-placeholder">
                      <div class="bg-primary text-primary-content w-8 rounded-full">
                        <span class="text-xs">{String.slice(client.name, 0..1) |> String.upcase}</span>
                      </div>
                    </div>
                    <div>
                      <div class="font-semibold">{client.name}</div>
                      <%= if client.contact_email do %>
                        <div class="text-sm opacity-70 flex items-center gap-1">
                          <.icon name="hero-envelope" class="size-3" />
                          <a href={"mailto:#{client.contact_email}"} class="link link-primary">
                            {client.contact_email}
                          </a>
                        </div>
                      <% end %>
                    </div>
                  </div>
                </:col>
                <:col :let={{_id, client}} label="Projects" class="hidden md:table-cell">
                  <div class="badge badge-secondary">
                    <.icon name="hero-folder" class="size-3 mr-1" />
                    {length(client.projects || [])} project<%= if length(client.projects || []) != 1, do: "s" %>
                  </div>
                </:col>
                <:col :let={{_id, client}} label="Status" class="hidden sm:table-cell">
                  <%= if client.active do %>
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
                </:col>
                <:action :let={{_id, client}}>
                  <div class="dropdown dropdown-end">
                    <div tabindex="0" role="button" class="btn btn-ghost btn-sm">
                      <.icon name="hero-ellipsis-vertical" class="size-4" />
                    </div>
                    <ul tabindex="0" class="dropdown-content menu bg-base-100 rounded-box z-[1] w-52 p-2 shadow">
                      <li>
                        <.link navigate={~p"/clients/#{client}"} class="flex items-center gap-2">
                          <.icon name="hero-eye" class="size-4" />
                          View
                        </.link>
                      </li>
                      <li>
                        <.link navigate={~p"/clients/#{client}/edit"} class="flex items-center gap-2">
                          <.icon name="hero-pencil-square" class="size-4" />
                          Edit
                        </.link>
                      </li>
                      <li>
                        <.link
                          phx-click={JS.push("delete", value: %{id: client.id}) |> hide("#clients-#{client.id}")}
                          data-confirm="Are you sure? This will also delete all associated projects and time entries."
                          class="flex items-center gap-2 text-error"
                        >
                          <.icon name="hero-trash" class="size-4" />
                          Delete
                        </.link>
                      </li>
                    </ul>
                  </div>
                </:action>
              </.table>
            </div>
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
