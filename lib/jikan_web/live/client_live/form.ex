defmodule JikanWeb.ClientLive.Form do
  use JikanWeb, :live_view

  alias Jikan.Tracking
  alias Jikan.Tracking.Client

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <div class="p-6 max-w-4xl mx-auto">
        <div class="breadcrumbs text-sm mb-6">
          <ul>
            <li>
              <.link navigate={return_path(@return_to, @client)} class="btn btn-ghost btn-sm gap-2">
                <.icon name="hero-arrow-left" class="size-4" />
                Back
              </.link>
            </li>
          </ul>
        </div>
        
        <.header>
          <.icon name="hero-building-office" class="size-8 inline" /> {@page_title}
          <:subtitle>
            <%= if @live_action == :new do %>
              Add a new client to start tracking projects and time
            <% else %>
              Update the client information and settings
            <% end %>
          </:subtitle>
        </.header>
        
        <div class="card bg-base-100 shadow-lg">
          <div class="card-body">
            <.form for={@form} id="client-form" phx-change="validate" phx-submit="save">
              <div class="space-y-6">
                <div class="form-control w-full">
                  <.input 
                    field={@form[:name]} 
                    type="text" 
                    label="Company Name" 
                    placeholder="Enter company name"
                  />
                  <label class="label">
                    <span class="label-text-alt">This will be used in project names and time entries</span>
                  </label>
                </div>
                
                <div class="form-control w-full">
                  <.input 
                    field={@form[:contact_email]} 
                    type="email" 
                    label="Contact Email" 
                    placeholder="contact@company.com"
                  />
                  <label class="label">
                    <span class="label-text-alt">Primary contact email for communications</span>
                  </label>
                </div>
                
                <div class="form-control">
                  <.input 
                    field={@form[:active]} 
                    type="checkbox" 
                    label="Active client" 
                  />
                  <label class="label">
                    <span class="label-text-alt">Only active clients can have new projects and time entries</span>
                  </label>
                </div>
              </div>
              
              <div class="card-actions justify-end mt-8">
                <.button variant="ghost" navigate={return_path(@return_to, @client)} class="gap-2">
                  <.icon name="hero-x-mark" class="size-4" />
                  Cancel
                </.button>
                <.button type="submit" phx-disable-with="Saving..." variant="primary" class="gap-2">
                  <.icon name="hero-check" class="size-5" />
                  Save Client
                </.button>
              </div>
            </.form>
          </div>
        </div>
      </div>
    </Layouts.app>
    """
  end

  @impl true
  def mount(params, _session, socket) do
    {:ok,
     socket
     |> assign(:return_to, return_to(params["return_to"]))
     |> apply_action(socket.assigns.live_action, params)}
  end

  defp return_to("show"), do: "show"
  defp return_to(_), do: "index"

  defp apply_action(socket, :edit, %{"id" => id}) do
    user = socket.assigns.current_user
    client = Tracking.get_client!(user, id)

    socket
    |> assign(:page_title, "Edit Client")
    |> assign(:client, client)
    |> assign(:form, to_form(Tracking.change_client(client)))
  end

  defp apply_action(socket, :new, _params) do
    client = %Client{}

    socket
    |> assign(:page_title, "New Client")
    |> assign(:client, client)
    |> assign(:form, to_form(Tracking.change_client(client)))
  end

  @impl true
  def handle_event("validate", %{"client" => client_params}, socket) do
    changeset = Tracking.change_client(socket.assigns.client, client_params)
    {:noreply, assign(socket, form: to_form(changeset, action: :validate))}
  end

  def handle_event("save", %{"client" => client_params}, socket) do
    save_client(socket, socket.assigns.live_action, client_params)
  end

  defp save_client(socket, :edit, client_params) do
    case Tracking.update_client(socket.assigns.client, client_params) do
      {:ok, client} ->
        {:noreply,
         socket
         |> put_flash(:info, "Client updated successfully")
         |> push_navigate(to: return_path(socket.assigns.return_to, client))}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp save_client(socket, :new, client_params) do
    user = socket.assigns.current_user
    client_params = Map.put(client_params, "user_id", user.id)
    
    case Tracking.create_client(user, client_params) do
      {:ok, client} ->
        {:noreply,
         socket
         |> put_flash(:info, "Client created successfully")
         |> push_navigate(to: return_path(socket.assigns.return_to, client))}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp return_path("index", _client), do: ~p"/clients"
  defp return_path("show", client), do: ~p"/clients/#{client}"
end
