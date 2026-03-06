defmodule JikanWeb.ProjectLive.Index do
  use JikanWeb, :live_view

  alias Jikan.Tracking

  @impl true
  def render(assigns) do
    ~H"""
    <Layouts.app flash={@flash}>
      <div class="p-1">
        <.header>
          <.icon name="hero-folder" class="size-8 inline" /> Projects
          <:subtitle>Manage your projects and track their progress</:subtitle>
          <:actions>
            <.button variant="primary" navigate={~p"/projects/new"} class="gap-2">
              <.icon name="hero-plus" class="size-5" />
              New Project
            </.button>
          </:actions>
        </.header>
        
        <div class="card bg-base-100 shadow-lg">
          <div class="card-body p-0">
            <div class="overflow-x-auto">
              <.table
                id="projects"
                rows={@streams.projects}
                row_click={fn {_id, project} -> JS.navigate(~p"/projects/#{project}") end}
              >
                <:col :let={{_id, project}} label="Project">
                  <div class="flex items-center gap-3">
                    <div class="avatar avatar-placeholder">
                      <div class="text-white w-8 rounded-full" style={"background-color: #{project.color || "#666"}"}>
                        <span class="text-xs">{String.slice(project.name, 0..1) |> String.upcase}</span>
                      </div>
                    </div>
                    <div>
                      <div class="font-semibold">{project.name}</div>
                      <div class="text-sm opacity-70">{project.client.name}</div>
                    </div>
                  </div>
                </:col>
                <:col :let={{_id, project}} label="Description" class="hidden lg:table-cell">
                  <div class="max-w-xs">
                    <span class="text-base-content">
                      <%= if project.description && String.trim(project.description) != "" do %>
                        {String.slice(project.description, 0, 50)}<%= if String.length(project.description) > 50, do: "..." %>
                      <% else %>
                        <span class="italic opacity-50">No description</span>
                      <% end %>
                    </span>
                  </div>
                </:col>
                <:col :let={{_id, project}} label="Status" class="hidden md:table-cell">
                  <%= if project.archived do %>
                    <div class="badge badge-ghost gap-1">
                      <.icon name="hero-archive-box" class="size-3" />
                      Archived
                    </div>
                  <% else %>
                    <div class="badge badge-success gap-1">
                      <.icon name="hero-check-circle" class="size-3" />
                      Active
                    </div>
                  <% end %>
                </:col>
                <:action :let={{_id, project}}>
                  <div class="dropdown dropdown-end">
                    <div tabindex="0" role="button" class="btn btn-ghost btn-sm">
                      <.icon name="hero-ellipsis-vertical" class="size-4" />
                    </div>
                    <ul tabindex="0" class="dropdown-content menu bg-base-100 rounded-box z-[1] w-52 p-2 shadow">
                      <li>
                        <.link navigate={~p"/projects/#{project}"} class="flex items-center gap-2">
                          <.icon name="hero-eye" class="size-4" />
                          View
                        </.link>
                      </li>
                      <li>
                        <.link navigate={~p"/projects/#{project}/edit"} class="flex items-center gap-2">
                          <.icon name="hero-pencil-square" class="size-4" />
                          Edit
                        </.link>
                      </li>
                      <li>
                        <.link
                          phx-click={JS.push("delete", value: %{id: project.id}) |> hide("#projects-#{project.id}")}
                          data-confirm="Are you sure? This will also delete all associated time entries."
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
     |> assign(:page_title, "Listing Projects")
     |> stream(:projects, list_projects(user))}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    user = socket.assigns.current_user
    project = Tracking.get_project!(user, id)
    {:ok, _} = Tracking.delete_project(project)

    {:noreply, stream_delete(socket, :projects, project)}
  end

  defp list_projects(user) do
    Tracking.list_projects(user)
  end
end
