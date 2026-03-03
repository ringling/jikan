defmodule JikanWeb.ProjectLive.Form do
  use JikanWeb, :live_view

  alias Jikan.Tracking
  alias Jikan.Tracking.Project

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <div class="max-w-4xl">
        <div class="mb-8">
          <.link navigate={return_path(@return_to, @project)} class="text-blue-600 hover:text-blue-800 flex items-center gap-1 mb-4">
            <.icon name="hero-arrow-left" class="size-4" />
            Back
          </.link>
          
          <h1 class="text-3xl font-bold text-gray-900 flex items-center gap-2">
            <.icon name="hero-folder" class="size-8" />
            {@page_title}
          </h1>
        </div>
        
        <div class="bg-white rounded-lg shadow">
          <div class="p-6">
            <.form for={@form} id="project-form" phx-change="validate" phx-submit="save" class="space-y-6">
              <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
                <div class="col-span-2">
                  <.input 
                    field={@form[:client_id]} 
                    type="select" 
                    label="Client" 
                    options={Enum.map(@clients, &{&1.name, &1.id})}
                    prompt="Choose a client"
                  />
                </div>
                
                <div class="col-span-2">
                  <.input 
                    field={@form[:name]} 
                    type="text" 
                    label="Project Name" 
                    placeholder="Enter project name"
                  />
                </div>
                
                <div class="col-span-2">
                  <.input 
                    field={@form[:description]} 
                    type="textarea" 
                    label="Description" 
                    placeholder="Describe the project..."
                  />
                </div>
                
                <div>
                  <.input 
                    field={@form[:color]} 
                    type="color" 
                    label="Project Color" 
                  />
                </div>
                
                <div class="flex items-end">
                  <.input 
                    field={@form[:archived]} 
                    type="checkbox" 
                    label="Archive this project" 
                  />
                </div>
              </div>
              
              <div class="flex items-center justify-end gap-4 pt-4 border-t">
                <.button navigate={return_path(@return_to, @project)} class="btn-outline">
                  Cancel
                </.button>
                <.button phx-disable-with="Saving..." variant="primary" class="flex items-center gap-2">
                  <.icon name="hero-check" class="size-5" />
                  Save Project
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
    project = Tracking.get_project!(user, id)
    clients = Tracking.list_clients(user)

    socket
    |> assign(:page_title, "Edit Project")
    |> assign(:project, project)
    |> assign(:clients, clients)
    |> assign(:form, to_form(Tracking.change_project(project)))
  end

  defp apply_action(socket, :new, _params) do
    user = socket.assigns.current_user
    project = %Project{}
    clients = Tracking.list_clients(user)

    socket
    |> assign(:page_title, "New Project")
    |> assign(:project, project)
    |> assign(:clients, clients)
    |> assign(:form, to_form(Tracking.change_project(project)))
  end

  @impl true
  def handle_event("validate", %{"project" => project_params}, socket) do
    changeset = Tracking.change_project(socket.assigns.project, project_params)
    {:noreply, assign(socket, form: to_form(changeset, action: :validate))}
  end

  def handle_event("save", %{"project" => project_params}, socket) do
    save_project(socket, socket.assigns.live_action, project_params)
  end

  defp save_project(socket, :edit, project_params) do
    case Tracking.update_project(socket.assigns.project, project_params) do
      {:ok, project} ->
        {:noreply,
         socket
         |> put_flash(:info, "Project updated successfully")
         |> push_navigate(to: return_path(socket.assigns.return_to, project))}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp save_project(socket, :new, project_params) do
    user = socket.assigns.current_user
    project_params = Map.put(project_params, "user_id", user.id)
    
    case Tracking.create_project(user, project_params) do
      {:ok, project} ->
        {:noreply,
         socket
         |> put_flash(:info, "Project created successfully")
         |> push_navigate(to: return_path(socket.assigns.return_to, project))}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp return_path("index", _project), do: ~p"/projects"
  defp return_path("show", project), do: ~p"/projects/#{project}"
end
