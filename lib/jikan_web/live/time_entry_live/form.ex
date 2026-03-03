defmodule JikanWeb.TimeEntryLive.Form do
  use JikanWeb, :live_view

  alias Jikan.Tracking
  alias Jikan.Tracking.TimeEntry

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <div class="max-w-4xl">
        <div class="mb-8">
          <.link navigate={return_path(@return_to, @time_entry)} class="text-blue-600 hover:text-blue-800 flex items-center gap-1 mb-4">
            <.icon name="hero-arrow-left" class="size-4" />
            Back
          </.link>
          
          <h1 class="text-3xl font-bold text-gray-900 flex items-center gap-2">
            <.icon name="hero-clock" class="size-8" />
            {@page_title}
          </h1>
        </div>
        
        <div class="bg-white rounded-lg shadow">
          <div class="p-6">
            <.form for={@form} id="time_entry-form" phx-change="validate" phx-submit="save" class="space-y-6">
              <div class="grid grid-cols-1 md:grid-cols-2 gap-6">
                <div class="col-span-2">
                  <.input 
                    field={@form[:project_id]} 
                    type="select" 
                    label="Project" 
                    options={Enum.map(@projects, &{&1.name, &1.id})}
                    prompt="Choose a project"
                  />
                </div>
                
                <div class="col-span-2">
                  <.input 
                    field={@form[:description]} 
                    type="text" 
                    label="Description" 
                    placeholder="What did you work on?"
                  />
                </div>
                
                <div>
                  <.input field={@form[:date]} type="date" label="Date" />
                </div>
                
                <div>
                  <.input 
                    field={@form[:duration_minutes]} 
                    type="number" 
                    label="Duration (minutes)" 
                    placeholder="90"
                  />
                </div>
                
                <div>
                  <.input field={@form[:start_time]} type="time" label="Start Time (optional)" />
                </div>
                
                <div>
                  <.input field={@form[:end_time]} type="time" label="End Time (optional)" />
                </div>
                
                <div class="col-span-2">
                  <.input field={@form[:billable]} type="checkbox" label="Mark as billable" />
                </div>
              </div>
              
              <div class="flex items-center justify-end gap-4 pt-4 border-t">
                <.button navigate={return_path(@return_to, @time_entry)} class="btn-outline">
                  Cancel
                </.button>
                <.button phx-disable-with="Saving..." variant="primary" class="flex items-center gap-2">
                  <.icon name="hero-check" class="size-5" />
                  Save Entry
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
    time_entry = Tracking.get_time_entry!(user, id)
    projects = Tracking.list_projects(user)

    socket
    |> assign(:page_title, "Edit Time Entry")
    |> assign(:time_entry, time_entry)
    |> assign(:projects, projects)
    |> assign(:form, to_form(Tracking.change_time_entry(time_entry)))
  end

  defp apply_action(socket, :new, _params) do
    user = socket.assigns.current_user
    time_entry = %TimeEntry{}
    
    # Load projects for the dropdown
    projects = Tracking.list_projects(user)

    socket
    |> assign(:page_title, "New Time Entry")
    |> assign(:time_entry, time_entry)
    |> assign(:projects, projects)
    |> assign(:form, to_form(Tracking.change_time_entry(time_entry)))
  end

  @impl true
  def handle_event("validate", %{"time_entry" => time_entry_params}, socket) do
    changeset = Tracking.change_time_entry(socket.assigns.time_entry, time_entry_params)
    {:noreply, assign(socket, form: to_form(changeset, action: :validate))}
  end

  def handle_event("save", %{"time_entry" => time_entry_params}, socket) do
    save_time_entry(socket, socket.assigns.live_action, time_entry_params)
  end

  defp save_time_entry(socket, :edit, time_entry_params) do
    case Tracking.update_time_entry(socket.assigns.time_entry, time_entry_params) do
      {:ok, time_entry} ->
        {:noreply,
         socket
         |> put_flash(:info, "Time entry updated successfully")
         |> push_navigate(to: return_path(socket.assigns.return_to, time_entry))}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp save_time_entry(socket, :new, time_entry_params) do
    user = socket.assigns.current_user
    time_entry_params = Map.put(time_entry_params, "user_id", user.id)
    
    case Tracking.create_time_entry(user, time_entry_params) do
      {:ok, time_entry} ->
        {:noreply,
         socket
         |> put_flash(:info, "Time entry created successfully")
         |> push_navigate(to: return_path(socket.assigns.return_to, time_entry))}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign(socket, form: to_form(changeset))}
    end
  end

  defp return_path("index", _time_entry), do: ~p"/time-entries"
  defp return_path("show", time_entry), do: ~p"/time-entries/#{time_entry}"
end
