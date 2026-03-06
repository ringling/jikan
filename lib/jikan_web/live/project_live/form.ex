defmodule JikanWeb.ProjectLive.Form do
  use JikanWeb, :live_view

  alias Jikan.Tracking
  alias Jikan.Tracking.Project

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <div class="p-1">
        <div class="breadcrumbs text-sm mb-6">
          <ul>
            <li>
              <.link navigate={return_path(@return_to, @project)} class="btn btn-ghost btn-sm gap-2">
                <.icon name="hero-arrow-left" class="size-4" />
                Back
              </.link>
            </li>
          </ul>
        </div>
        
        <.header>
          <.icon name="hero-folder" class="size-8 inline" /> {@page_title}
          <:subtitle>
            <%= if @live_action == :new do %>
              Create a new project to organize your time tracking
            <% else %>
              Update the project details and settings
            <% end %>
          </:subtitle>
        </.header>
        
        <div class="card bg-base-100 shadow-lg">
          <div class="card-body">
            <.form for={@form} id="project-form" phx-change="validate" phx-submit="save">
              <div class="space-y-6">
                <div class="form-control w-full">
                  <.input 
                    field={@form[:client_id]} 
                    type="select" 
                    label="Client" 
                    options={Enum.map(@clients, &{&1.name, &1.id})}
                    prompt="Choose a client"
                  />
                  <label class="label">
                    <span class="label-text-alt">Select which client this project belongs to</span>
                  </label>
                </div>
                
                <div class="form-control w-full">
                  <.input 
                    field={@form[:name]} 
                    type="text" 
                    label="Project Name" 
                    placeholder="Enter project name"
                  />
                  <label class="label">
                    <span class="label-text-alt">This will appear in time entry forms and reports</span>
                  </label>
                </div>
                
                <div class="form-control w-full">
                  <.input 
                    field={@form[:description]} 
                    type="textarea" 
                    label="Description" 
                    placeholder="Describe the project goals, scope, or other details..."
                  />
                  <label class="label">
                    <span class="label-text-alt">Optional project description for reference</span>
                  </label>
                </div>
                
                <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
                  <div class="form-control w-full">
                    <.input 
                      field={@form[:color]} 
                      type="color" 
                      label="Project Color" 
                    />
                    <label class="label">
                      <span class="label-text-alt">Used for visual identification in the UI</span>
                    </label>
                  </div>
                  
                  <div class="form-control">
                    <.input 
                      field={@form[:archived]} 
                      type="checkbox" 
                      label="Archive this project" 
                    />
                    <label class="label">
                      <span class="label-text-alt">Archived projects won't appear in new time entries</span>
                    </label>
                  </div>
                </div>
              </div>
              
              <div class="card-actions justify-end mt-8">
                <.button variant="ghost" navigate={return_path(@return_to, @project)} class="gap-2">
                  <.icon name="hero-x-mark" class="size-4" />
                  Cancel
                </.button>
                <.button type="submit" phx-disable-with="Saving..." variant="primary" class="gap-2">
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
