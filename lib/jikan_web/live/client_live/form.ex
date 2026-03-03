defmodule JikanWeb.ClientLive.Form do
  use JikanWeb, :live_view

  alias Jikan.Tracking
  alias Jikan.Tracking.Client

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <div class="max-w-4xl">
        <div class="mb-8">
          <.link navigate={return_path(@return_to, @client)} class="text-blue-600 hover:text-blue-800 flex items-center gap-1 mb-4">
            <.icon name="hero-arrow-left" class="size-4" />
            Back
          </.link>
          
          <h1 class="text-3xl font-bold text-gray-900 flex items-center gap-2">
            <.icon name="hero-building-office" class="size-8" />
            {@page_title}
          </h1>
        </div>
        
        <div class="bg-white rounded-lg shadow">
          <div class="p-6">
            <.form for={@form} id="client-form" phx-change="validate" phx-submit="save" class="space-y-6">
              <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
                <div class="col-span-2">
                  <.input 
                    field={@form[:name]} 
                    type="text" 
                    label="Company Name" 
                    placeholder="Enter company name"
                  />
                </div>
                
                <div class="col-span-2">
                  <.input 
                    field={@form[:contact_email]} 
                    type="email" 
                    label="Contact Email" 
                    placeholder="contact@company.com"
                  />
                </div>
                
                <div class="col-span-2">
                  <.input 
                    field={@form[:active]} 
                    type="checkbox" 
                    label="Active client" 
                  />
                </div>
              </div>
              
              <div class="flex items-center justify-end gap-4 pt-4 border-t">
                <.button navigate={return_path(@return_to, @client)} class="btn-outline">
                  Cancel
                </.button>
                <.button phx-disable-with="Saving..." variant="primary" class="flex items-center gap-2">
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
