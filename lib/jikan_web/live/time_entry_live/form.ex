defmodule JikanWeb.TimeEntryLive.Form do
  use JikanWeb, :live_view

  alias Jikan.Tracking
  alias Jikan.Tracking.TimeEntry
  alias Jikan.Timezone

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <div class="p-1">
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

              <div class="divider"></div>

              <!-- Billing Information Section -->
              <div class="mb-8">
                <h3 class="text-lg font-semibold text-base-content mb-4 flex items-center gap-2">
                  <.icon name="hero-currency-dollar" class="size-5" />
                  Billing Information
                </h3>
                <div class="grid grid-cols-1 md:grid-cols-3 gap-6">
                  <!-- Current Hourly Rate -->
                  <div>
                    <.input 
                      field={@form[:hourly_rate]} 
                      type="number" 
                      label="Hourly Rate (DKK)" 
                      placeholder="0.00"
                      step="0.01"
                      min="0"
                    />
                    <label class="label">
                      <span class="label-text-alt text-xs opacity-70">
                        <%= cond do %>
                          <% Phoenix.HTML.Form.input_value(@form, :hourly_rate) && Phoenix.HTML.Form.input_value(@form, :project_id) -> %>
                            <%= case get_rate_source(@projects, Phoenix.HTML.Form.input_value(@form, :project_id)) do %>
                              <% {:project, rate} -> %><span class="text-info">From project (DKK <%= rate %>)</span>
                              <% {:client, rate} -> %><span class="text-warning">From client default (DKK <%= rate %>)</span>
                              <% :none -> %><span class="text-base-content/50">No rate set for this project</span>
                            <% end %>
                          <% true -> %>
                            <span class="text-base-content/50">Select project to see applicable rate</span>
                        <% end %>
                      </span>
                    </label>
                  </div>
                  
                  <!-- Total Amount -->
                  <div>
                    <div class="form-control w-full">
                      <label class="label">
                        <span class="label-text font-medium">Total Amount (DKK)</span>
                      </label>
                      <div class="input input-bordered flex items-center bg-base-200">
                        <span class="font-mono text-lg">
                          <%= if get_total_amount(@form) do %>
                            DKK <%= get_total_amount(@form) %>
                          <% else %>
                            DKK 0.00
                          <% end %>
                        </span>
                      </div>
                      <label class="label">
                        <span class="label-text-alt text-xs opacity-70">
                          <%= if @form.data.billable do %>
                            Calculated from billable time
                          <% else %>
                            Non-billable entry
                          <% end %>
                        </span>
                      </label>
                    </div>
                  </div>
                  
                  <!-- Update Rate Button -->
                  <div>
                    <div class="form-control w-full">
                      <label class="label">
                        <span class="label-text font-medium">Rate Management</span>
                      </label>
                      <button
                        type="button"
                        phx-click="update_rate"
                        class={[
                          "btn btn-outline btn-info gap-2 w-full",
                          unless(Phoenix.HTML.Form.input_value(@form, :project_id), do: "btn-disabled")
                        ]}
                        disabled={!Phoenix.HTML.Form.input_value(@form, :project_id)}
                      >
                        <.icon name="hero-arrow-path" class="size-4" />
                        Update Rate & Total
                      </button>
                      <label class="label">
                        <span class="label-text-alt text-xs opacity-70">
                          Apply current project/client rate
                        </span>
                      </label>
                    </div>
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
    # Load projects with client data preloaded for rate information
    projects = Tracking.list_projects(user) |> Jikan.Repo.preload(:client)

    # Always convert UTC times to local timezone for display in forms
    # This ensures consistent user experience regardless of when the entry was created
    time_entry_for_display = convert_times_to_local_for_display(time_entry)

    socket
    |> assign(:page_title, "Edit Time Entry")
    |> assign(:time_entry, time_entry_for_display)
    |> assign(:projects, projects)
    |> assign(:form, to_form(Tracking.change_time_entry(time_entry_for_display)))
  end

  defp apply_action(socket, :new, _params) do
    user = socket.assigns.current_user
    time_entry = %TimeEntry{}
    
    # Load projects with client data preloaded for rate information
    projects = Tracking.list_projects(user) |> Jikan.Repo.preload(:client)

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
    # Convert times from local to UTC before saving
    time_entry_params = convert_times_to_utc_for_save(time_entry_params)
    save_time_entry(socket, socket.assigns.live_action, time_entry_params)
  end

  def handle_event("update_rate", _params, socket) do
    project_id = Phoenix.HTML.Form.input_value(socket.assigns.form, :project_id)
    
    if project_id do
      case determine_applicable_rate(socket.assigns.projects, project_id) do
        {:ok, rate, source} ->
          # Get current form data and merge with existing time entry data
          current_params = socket.assigns.form.params || %{}
          
          # Get current form values for calculation
          duration_minutes = Phoenix.HTML.Form.input_value(socket.assigns.form, :duration_minutes) || 
                           socket.assigns.time_entry.duration_minutes || 0
          pause_duration_minutes = Phoenix.HTML.Form.input_value(socket.assigns.form, :pause_duration_minutes) || 
                                 socket.assigns.time_entry.pause_duration_minutes || 0
          billable = Phoenix.HTML.Form.input_value(socket.assigns.form, :billable)
          billable = if billable == nil, do: socket.assigns.time_entry.billable, else: billable
          
          # Update params with new rate and trigger recalculation
          updated_params = current_params
          |> Map.put("hourly_rate", rate)
          |> Map.put("duration_minutes", duration_minutes)
          |> Map.put("pause_duration_minutes", pause_duration_minutes) 
          |> Map.put("billable", billable)
          
          # Create changeset to trigger total_amount calculation
          changeset = Tracking.change_time_entry(socket.assigns.time_entry, updated_params)
          
          # Flash message based on rate source
          message = case source do
            :project -> "Rate updated from project setting (DKK #{rate})"
            :client -> "Rate updated from client default (DKK #{rate})"
          end
          
          {:noreply,
           socket
           |> assign(form: to_form(changeset, action: :validate))
           |> put_flash(:info, message)}
        
        {:error, :no_rate} ->
          {:noreply,
           socket
           |> put_flash(:warning, "No rate set for this project or its client")}
      end
    else
      {:noreply,
       socket
       |> put_flash(:error, "Please select a project first")}
    end
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

  defp get_rate_source(projects, project_id) when is_binary(project_id) do
    get_rate_source(projects, String.to_integer(project_id))
  rescue
    ArgumentError -> :none
  end

  defp get_rate_source(projects, project_id) when is_integer(project_id) do
    case Enum.find(projects, &(&1.id == project_id)) do
      nil -> :none
      project ->
        cond do
          project.hourly_rate -> {:project, project.hourly_rate}
          project.client && project.client.default_hourly_rate -> {:client, project.client.default_hourly_rate}
          true -> :none
        end
    end
  end

  defp get_rate_source(_projects, _), do: :none

  defp determine_applicable_rate(projects, project_id) when is_binary(project_id) do
    determine_applicable_rate(projects, String.to_integer(project_id))
  rescue
    ArgumentError -> {:error, :no_rate}
  end

  defp determine_applicable_rate(projects, project_id) when is_integer(project_id) do
    case get_rate_source(projects, project_id) do
      {:project, rate} -> {:ok, rate, :project}
      {:client, rate} -> {:ok, rate, :client}
      :none -> {:error, :no_rate}
    end
  end

  defp get_total_amount(form) do
    # Try to get total_amount from the changeset data first
    case Phoenix.HTML.Form.input_value(form, :total_amount) do
      nil -> 
        # If not in form data, try to get it from the original data
        case form.data do
          %{total_amount: amount} when not is_nil(amount) -> 
            # Format as string with 2 decimal places
            :erlang.float_to_binary(Decimal.to_float(amount), [decimals: 2])
          _ -> nil
        end
      amount when not is_nil(amount) ->
        # Format as string with 2 decimal places
        :erlang.float_to_binary(Decimal.to_float(amount), [decimals: 2])
    end
  end


  # Convert times from UTC to local timezone for display in form
  defp convert_times_to_local_for_display(time_entry) do
    %{time_entry | 
      start_time: convert_time_to_local(time_entry.start_time, time_entry.date),
      end_time: convert_time_to_local(time_entry.end_time, time_entry.date)
    }
  end

  defp convert_time_to_local(nil, _date), do: nil
  defp convert_time_to_local(time, date) do
    local_dt = Timezone.time_to_local(time, date)
    DateTime.to_time(local_dt)
  end

  # Convert times from local timezone to UTC for saving
  defp convert_times_to_utc_for_save(params) do
    date = params["date"] || Date.utc_today()
    date = if is_binary(date), do: Date.from_iso8601!(date), else: date

    params
    |> maybe_convert_time_to_utc("start_time", date)
    |> maybe_convert_time_to_utc("end_time", date)
  end

  defp maybe_convert_time_to_utc(params, field, date) do
    case params[field] do
      nil -> params
      "" -> params
      time_string when is_binary(time_string) ->
        # Parse the time string and convert to UTC
        case Time.from_iso8601(time_string <> ":00") do
          {:ok, local_time} ->
            utc_time = Timezone.time_to_utc(local_time, date)
            Map.put(params, field, Time.to_string(utc_time))
          _ -> params
        end
      _ -> params
    end
  end
end
