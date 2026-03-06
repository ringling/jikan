defmodule JikanWeb.TimeEntryLive.Form do
  use JikanWeb, :live_view

  alias Jikan.Tracking
  alias Jikan.Tracking.TimeEntry

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <div class="p-6 max-w-4xl mx-auto">
        <div class="breadcrumbs text-sm mb-6">
          <ul>
            <li>
              <.link navigate={return_path(@return_to, @time_entry)} class="btn btn-ghost btn-sm gap-2">
                <.icon name="hero-arrow-left" class="size-4" />
                Back
              </.link>
            </li>
          </ul>
        </div>
        
        <.header>
          <.icon name="hero-clock" class="size-8 inline" /> {@page_title}
          <:subtitle>
            <%= if @live_action == :new do %>
              Create a new time entry for your project work
            <% else %>
              Modify this time entry's details
            <% end %>
          </:subtitle>
        </.header>
        
        <div class="card bg-base-100 shadow-lg">
          <div class="card-body">
            <.form for={@form} id="time_entry-form" phx-change="validate" phx-submit="save">
              <!-- Project & Description Section -->
              <div class="mb-8">
                <h3 class="text-lg font-semibold text-base-content mb-4 flex items-center gap-2">
                  <.icon name="hero-folder" class="size-5" />
                  Project Details
                </h3>
                <div class="grid grid-cols-1 gap-6">
                  <div>
                    <.input 
                      field={@form[:project_id]} 
                      type="select" 
                      label="Project" 
                      options={Enum.map(@projects, &{"#{&1.name} - #{&1.client.name}", &1.id})}
                      prompt="Choose a project"
                    />
                  </div>
                  
                  <div>
                    <.input 
                      field={@form[:description]} 
                      type="text" 
                      label="Description" 
                      placeholder="What did you work on?"
                    />
                  </div>
                </div>
              </div>

              <div class="divider"></div>

              <!-- Date & Time Section -->
              <div class="mb-8">
                <h3 class="text-lg font-semibold text-base-content mb-4 flex items-center gap-2">
                  <.icon name="hero-clock" class="size-5" />
                  Time & Date
                </h3>
                <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
                  <div>
                    <.input field={@form[:date]} type="date" label="Date" />
                  </div>
                  
                  <div>
                    <.input 
                      field={@form[:duration_minutes]} 
                      type="number" 
                      label="Duration (minutes)" 
                      placeholder="90"
                      min="1"
                    />
                    <label class="label">
                      <span class="label-text-alt text-xs opacity-70">Enter total work time in minutes</span>
                    </label>
                  </div>
                  
                  <div>
                    <.input 
                      field={@form[:pause_duration_minutes]} 
                      type="number" 
                      label="Pause Duration (minutes)" 
                      placeholder="0"
                      min="0"
                    />
                    <label class="label">
                      <span class="label-text-alt text-xs opacity-70">Lunch breaks or other pauses</span>
                    </label>
                  </div>
                  
                  <div>
                    <.input field={@form[:start_time]} type="time" label="Start Time (optional)" />
                    <label class="label">
                      <span class="label-text-alt text-xs opacity-70">When you started working</span>
                    </label>
                  </div>
                  
                  <div>
                    <.input field={@form[:end_time]} type="time" label="End Time (optional)" />
                    <label class="label">
                      <span class="label-text-alt text-xs opacity-70">When you finished working</span>
                    </label>
                  </div>
                  
                  <div class="flex items-center">
                    <.input field={@form[:billable]} type="checkbox" label="Mark as billable" />
                  </div>
                </div>
              </div>
              
              <div class="card-actions justify-end">
                <.button variant="ghost" navigate={return_path(@return_to, @time_entry)} class="gap-2">
                  <.icon name="hero-x-mark" class="size-4" />
                  Cancel
                </.button>
                <.button type="submit" phx-disable-with="Saving..." variant="primary" class="gap-2">
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
