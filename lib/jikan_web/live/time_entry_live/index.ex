defmodule JikanWeb.TimeEntryLive.Index do
  use JikanWeb, :live_view

  alias Jikan.Tracking

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <div class="p-1">
        <.header>
          <.icon name="hero-clock" class="size-8 inline" /> Time Entries
          <div class="badge badge-neutral badge-lg ml-3">{@entry_count}</div>
          <:subtitle>Track and manage your time entries</:subtitle>
          <:actions>
            <.button 
              variant="outline" 
              href={build_export_url(@filters)}
              class="gap-2"
            >
              <.icon name="hero-arrow-down-tray" class="size-5" />
              Download CSV
            </.button>
            <.button variant="primary" navigate={~p"/time-entries/new"} class="gap-2">
              <.icon name="hero-plus" class="size-5" />
              New Entry
            </.button>
          </:actions>
        </.header>
        
        <!-- Filter Panel -->
        <div class="card bg-base-100 shadow-sm mb-4">
          <div class="card-body p-0">
            <div class="collapse collapse-arrow bg-base-100">
              <input type="checkbox" checked={@show_filters} phx-click="toggle_filters" />
              <div class="collapse-title text-lg font-semibold flex items-center gap-2">
                <.icon name="hero-funnel" class="size-5" />
                Filters
                <%= if has_active_filters?(@filters) do %>
                  <div class="badge badge-primary badge-sm">{Enum.count(@filters, fn {_k, v} -> v != "" end)}</div>
                <% end %>
                
                <!-- Active Filters Display when collapsed -->
                <%= if has_active_filters?(@filters) and !@show_filters do %>
                  <div class="flex flex-wrap gap-2 ml-4">
                    <%= for {key, value} <- @filters, value != "" and !is_nil(value) do %>
                      <div class="badge badge-outline badge-sm gap-1">
                        <span>
                          <%= case key do %>
                            <% "client_id" -> %>
                              <%= case Enum.find(@clients, &(&1.id == String.to_integer(value))) do
                                    nil -> "Unknown"
                                    client -> client.name
                                  end %>
                            <% "year" -> %>
                              <%= value %>
                            <% "month" -> %>
                              <%= if @filters["year"] && @filters["year"] != "" do %>
                                <%= @filters["year"] %> <%= Enum.find(month_options(), fn {_label, val} -> val == value end) |> elem(0) %>
                              <% else %>
                                <%= Enum.find(month_options(), fn {_label, val} -> val == value end) |> elem(0) %>
                              <% end %>
                            <% "week" -> %>
                              W<%= String.pad_leading(value, 2, "0") %>
                          <% end %>
                        </span>
                      </div>
                    <% end %>
                  </div>
                <% end %>
              </div>
              
              <div class="collapse-content">
                <div class="p-4">
                  <form phx-submit="apply_filters">
                    <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
                      <div class="form-control">
                        <label class="label">
                          <span class="label-text">Company</span>
                        </label>
                        <select 
                          name="filters[client_id]" 
                          class="select select-bordered w-full"
                          value={@filters["client_id"] || ""}
                        >
                          {Phoenix.HTML.Form.options_for_select(client_options(@clients), @filters["client_id"] || "")}
                        </select>
                      </div>
                      
                      <div class="form-control">
                        <label class="label">
                          <span class="label-text">Year</span>
                        </label>
                        <select 
                          name="filters[year]" 
                          class="select select-bordered w-full"
                          value={@filters["year"] || ""}
                        >
                          {Phoenix.HTML.Form.options_for_select(year_options(), @filters["year"] || "")}
                        </select>
                      </div>
                      
                      <div class="form-control">
                        <label class="label">
                          <span class="label-text">Month</span>
                        </label>
                        <select 
                          name="filters[month]" 
                          class="select select-bordered w-full"
                          value={@filters["month"] || ""}
                        >
                          {Phoenix.HTML.Form.options_for_select(month_options(), @filters["month"] || "")}
                        </select>
                      </div>
                      
                      <div class="form-control">
                        <label class="label">
                          <span class="label-text">Week</span>
                        </label>
                        <select 
                          name="filters[week]" 
                          class="select select-bordered w-full"
                          value={@filters["week"] || ""}
                        >
                          {Phoenix.HTML.Form.options_for_select(week_options(), @filters["week"] || "")}
                        </select>
                      </div>
                    </div>
                    
                    <div class="flex justify-end gap-2 mt-4">
                      <.button variant="ghost" phx-click="clear_filters" type="button" class="gap-2">
                        <.icon name="hero-x-mark" class="size-4" />
                        Clear Filters
                      </.button>
                      <.button variant="primary" type="submit" class="gap-2">
                        <.icon name="hero-magnifying-glass" class="size-4" />
                        Apply Filters
                      </.button>
                    </div>
                  </form>
                </div>
              </div>
            </div>
          </div>
        </div>
        
        <div class="card bg-base-100 shadow-lg">
          <div class="card-body p-0">
            <div class="overflow-x-auto">
              <.table
                id="time_entries"
                rows={@streams.time_entries}
                row_click={fn {_id, time_entry} -> JS.navigate(~p"/time-entries/#{time_entry}") end}
              >
                <:col :let={{_id, time_entry}} label="Project">
                  <div class="flex items-center gap-3">
                    <div class="avatar avatar-placeholder">
                      <div class="text-white w-8 rounded-full" style={"background-color: #{time_entry.project.color || "#666"}"}>
                        <span class="text-xs">{String.slice(time_entry.project.name, 0..1) |> String.upcase}</span>
                      </div>
                    </div>
                    <div>
                      <div class="font-semibold">{time_entry.project.name}</div>
                      <div class="text-sm opacity-70">{time_entry.project.client.name}</div>
                    </div>
                  </div>
                </:col>
                <:col :let={{_id, time_entry}} label="Description" class="hidden md:table-cell">
                  <span class="text-base-content">{time_entry.description || "-"}</span>
                </:col>
                <:col :let={{_id, time_entry}} label="Date">
                  <div class="badge badge-outline whitespace-nowrap">
                    {Calendar.strftime(time_entry.date, "%d.%m.%y")}
                  </div>
                </:col>
                <:col :let={{_id, time_entry}} label="Month" class="hidden lg:table-cell">
                  <div class="badge badge-neutral badge-sm gap-1">
                    <.icon name="hero-calendar" class="size-3" />
                    {format_month(time_entry.date)}
                  </div>
                </:col>
                <:col :let={{_id, time_entry}} label="Week" class="hidden lg:table-cell">
                  <div class="badge badge-secondary badge-sm gap-1">
                    <.icon name="hero-clock" class="size-3" />
                    W{format_week(time_entry.date)}
                  </div>
                </:col>
                <:col :let={{_id, time_entry}} label="Duration">
                  <div class="flex flex-col items-start">
                    <div class="badge badge-primary">
                      {format_duration(time_entry.duration_minutes)}
                    </div>
                    <%= if time_entry.pause_duration_minutes && time_entry.pause_duration_minutes > 0 do %>
                      <div class="badge badge-warning badge-sm mt-1">
                        <.icon name="hero-pause-circle" class="size-3 mr-1" />
                        {format_duration(time_entry.pause_duration_minutes)}
                      </div>
                    <% end %>
                  </div>
                </:col>
                <:col :let={{_id, time_entry}} label="Billable" class="hidden sm:table-cell">
                  <%= if time_entry.billable do %>
                    <div class="badge badge-success gap-1">
                      <.icon name="hero-check-circle" class="size-4" />
                      Billable
                    </div>
                  <% else %>
                    <div class="badge badge-ghost gap-1">
                      <.icon name="hero-x-circle" class="size-4" />
                      Non-billable
                    </div>
                  <% end %>
                </:col>
                <:col :let={{_id, time_entry}} label="Amount" class="hidden lg:table-cell">
                  <%= if time_entry.total_amount && time_entry.billable do %>
                    <div class="flex flex-col items-start">
                      <span class="font-semibold">DKK {time_entry.total_amount}</span>
                      <%= if time_entry.hourly_rate do %>
                        <span class="text-xs opacity-60">@{time_entry.hourly_rate}/hr</span>
                      <% end %>
                    </div>
                  <% else %>
                    <span class="text-base opacity-60">-</span>
                  <% end %>
                </:col>
                <:action :let={{_id, time_entry}}>
                  <div class="dropdown dropdown-end">
                    <div tabindex="0" role="button" class="btn btn-ghost btn-sm">
                      <.icon name="hero-ellipsis-vertical" class="size-4" />
                    </div>
                    <ul tabindex="0" class="dropdown-content menu bg-base-100 rounded-box z-[1] w-52 p-2 shadow">
                      <li>
                        <.link navigate={~p"/time-entries/#{time_entry}/edit"} class="flex items-center gap-2">
                          <.icon name="hero-pencil-square" class="size-4" />
                          Edit
                        </.link>
                      </li>
                      <li>
                        <.link
                          phx-click={JS.push("delete", value: %{id: time_entry.id}) |> hide("#time_entries-#{time_entry.id}")}
                          data-confirm="Are you sure?"
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
  
  defp format_duration(nil), do: "0:00"
  defp format_duration(minutes) do
    hours = div(minutes, 60)
    mins = rem(minutes, 60)
    "#{hours}:#{String.pad_leading(to_string(mins), 2, "0")}"
  end

  defp format_month(date) do
    case date.month do
      1 -> "Jan"
      2 -> "Feb" 
      3 -> "Mar"
      4 -> "Apr"
      5 -> "Maj"
      6 -> "Jun"
      7 -> "Jul"
      8 -> "Aug"
      9 -> "Sep"
      10 -> "Okt"
      11 -> "Nov"
      12 -> "Dec"
    end
  end

  defp format_week(date) do
    {_year, week} = :calendar.iso_week_number({date.year, date.month, date.day})
    String.pad_leading(to_string(week), 2, "0")
  end

  @impl true
  def mount(_params, _session, socket) do
    user = socket.assigns.current_user
    time_entries = list_time_entries(user, %{})
    
    {:ok,
     socket
     |> assign(:page_title, "Listing Time entries")
     |> assign(:filters, %{})
     |> assign(:clients, list_clients(user))
     |> assign(:show_filters, false)
     |> assign(:entry_count, length(time_entries))
     |> stream(:time_entries, time_entries)}
  end

  @impl true
  def handle_params(params, _uri, socket) do
    user = socket.assigns.current_user
    filters = build_filters_from_params(params)
    time_entries = list_time_entries(user, filters)
    
    {:noreply,
     socket
     |> assign(:filters, filters)
     |> assign(:entry_count, length(time_entries))
     |> stream(:time_entries, time_entries, reset: true)}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    user = socket.assigns.current_user
    time_entry = Tracking.get_time_entry!(user, id)
    {:ok, _} = Tracking.delete_time_entry(time_entry)

    {:noreply, 
     socket
     |> assign(:entry_count, socket.assigns.entry_count - 1)
     |> stream_delete(:time_entries, time_entry)}
  end

  def handle_event("toggle_filters", _params, socket) do
    {:noreply, assign(socket, :show_filters, !socket.assigns.show_filters)}
  end

  def handle_event("apply_filters", %{"filters" => filter_params}, socket) do
    user = socket.assigns.current_user
    filters = build_filters_from_params(filter_params)
    time_entries = list_time_entries(user, filters)
    
    {:noreply,
     socket
     |> assign(:filters, filters)
     |> assign(:entry_count, length(time_entries))
     |> stream(:time_entries, time_entries, reset: true)
     |> push_patch(to: ~p"/time-entries?#{filters}")}
  end

  def handle_event("clear_filters", _params, socket) do
    user = socket.assigns.current_user
    filters = %{}
    time_entries = list_time_entries(user, filters)
    
    {:noreply,
     socket
     |> assign(:filters, filters)
     |> assign(:entry_count, length(time_entries))
     |> stream(:time_entries, time_entries, reset: true)
     |> push_patch(to: ~p"/time-entries")}
  end

  defp list_time_entries(user, filters) do
    Tracking.list_time_entries(user, filters)
  end

  defp list_clients(user) do
    Tracking.list_clients(user)
  end

  defp build_filters_from_params(params) do
    %{}
    |> maybe_put_filter("client_id", params["client_id"])
    |> maybe_put_filter("year", params["year"])
    |> maybe_put_filter("month", params["month"])
    |> maybe_put_filter("week", params["week"])
  end

  defp maybe_put_filter(filters, _key, nil), do: filters
  defp maybe_put_filter(filters, _key, ""), do: filters
  defp maybe_put_filter(filters, key, value), do: Map.put(filters, key, value)

  defp month_options do
    [
      {"All Months", ""},
      {"Jan", "1"},
      {"Feb", "2"},
      {"Mar", "3"},
      {"Apr", "4"},
      {"Maj", "5"},
      {"Jun", "6"},
      {"Jul", "7"},
      {"Aug", "8"},
      {"Sep", "9"},
      {"Okt", "10"},
      {"Nov", "11"},
      {"Dec", "12"}
    ]
  end

  defp week_options do
    [{"All Weeks", ""}] ++ 
    Enum.map(1..53, fn week -> {"W#{String.pad_leading(to_string(week), 2, "0")}", to_string(week)} end)
  end

  defp year_options do
    current_year = Date.utc_today().year
    years = (current_year - 5)..(current_year + 1) |> Enum.to_list() |> Enum.reverse()
    [{"All Years", ""}] ++ Enum.map(years, fn year -> {to_string(year), to_string(year)} end)
  end

  defp client_options(clients) do
    [{"All Companies", ""}] ++ Enum.map(clients, &{&1.name, &1.id})
  end

  defp has_active_filters?(filters) do
    Enum.any?(filters, fn {_key, value} -> value != "" and not is_nil(value) end)
  end

  defp build_export_url(filters) do
    base_url = "/exports/time-entries"
    if has_active_filters?(filters) do
      query_params = 
        filters
        |> Enum.reject(fn {_key, value} -> value == "" or is_nil(value) end)
        |> Enum.into(%{})
        |> URI.encode_query()
      
      "#{base_url}?#{query_params}"
    else
      base_url
    end
  end
end
