defmodule JikanWeb.Router do
  use JikanWeb, :router

  import JikanWeb.UserAuth

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {JikanWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :fetch_current_scope_for_user
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  # Public routes
  scope "/", JikanWeb do
    pipe_through :browser

    get "/", PageController, :home
  end

  # Employee-level routes (all authenticated users)
  scope "/", JikanWeb do
    pipe_through [:browser, :require_authenticated_user]

    live_session :authenticated,
      on_mount: [{JikanWeb.UserAuth, :ensure_authenticated}] do
      
      live "/dashboard", DashboardLive
      
      live "/time-entries", TimeEntryLive.Index, :index
      live "/time-entries/new", TimeEntryLive.Form, :new
      live "/time-entries/:id", TimeEntryLive.Show, :show
      live "/time-entries/:id/edit", TimeEntryLive.Form, :edit
    end

    # User settings (non-LiveView routes)
    get "/users/settings", UserSettingsController, :edit
    put "/users/settings", UserSettingsController, :update
    get "/users/settings/confirm-email/:token", UserSettingsController, :confirm_email
  end

  # Manager+ routes
  scope "/", JikanWeb do
    pipe_through [:browser, :require_authenticated_user]

    live_session :manager_required,
      on_mount: [{JikanWeb.Live.Hooks.AuthorizeHook, :manager_required}] do
      
      live "/projects", ProjectLive.Index, :index
      live "/projects/new", ProjectLive.Form, :new
      live "/projects/:id", ProjectLive.Show, :show
      live "/projects/:id/edit", ProjectLive.Form, :edit
      
      live "/clients", ClientLive.Index, :index
      live "/clients/new", ClientLive.Form, :new
      live "/clients/:id", ClientLive.Show, :show
      live "/clients/:id/edit", ClientLive.Form, :edit
      
      # live "/reports", ReportLive  # TODO: Implement ReportLive
    end
    
    # Export also requires manager+
    # get "/exports/time-entries", ExportController, :time_entries  # TODO: Implement ExportController
  end

  # Admin-only routes
  scope "/admin", JikanWeb do
    pipe_through [:browser, :require_authenticated_user]

    live_session :admin_required,
      on_mount: [{JikanWeb.Live.Hooks.AuthorizeHook, :admin_required}] do
      
      # live "/users", Admin.UserLive.Index  # TODO: Implement Admin.UserLive.Index
      # live "/users/:id/edit", Admin.UserLive.Edit  # TODO: Implement Admin.UserLive.Edit
    end
  end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:jikan, :dev_routes) do
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: JikanWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end

  ## Authentication routes

  scope "/", JikanWeb do
    pipe_through [:browser, :redirect_if_user_is_authenticated]

    get "/users/register", UserRegistrationController, :new
    post "/users/register", UserRegistrationController, :create
  end

  scope "/", JikanWeb do
    pipe_through [:browser]

    get "/users/log-in", UserSessionController, :new
    get "/users/log-in/:token", UserSessionController, :confirm
    post "/users/log-in", UserSessionController, :create
    delete "/users/log-out", UserSessionController, :delete
  end
end