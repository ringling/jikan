# Claude Code Prompt: Elixir LiveView Time Registration App

## Project Overview

Build a full-stack time registration web application using **Elixir**, **Phoenix LiveView**, and **SQLite**. The app allows users to log work hours against projects/clients, view summaries, and manage their time entries — all with real-time UI updates via LiveView (no JavaScript needed for core functionality).

---

## Tech Stack

| Layer        | Technology                          |
|--------------|-------------------------------------|
| Language     | Elixir 1.16+                        |
| Framework    | Phoenix 1.7+ with LiveView 0.20+   |
| Database     | SQLite via `ecto_sqlite3`           |
| Auth         | `mix phx.gen.auth` (built-in)      |
| CSS          | Tailwind CSS (ships with Phoenix)   |
| Build        | Mix, esbuild (Phoenix defaults)     |

---

## Step-by-Step Instructions

### 1. Project Bootstrap

```bash
mix phx.new time_reg --database sqlite3
cd time_reg
mix deps.get
mix ecto.create
```

Verify `mix.exs` has `{:ecto_sqlite3, "~> 0.17"}` and `config/dev.exs` points to a `.db` file.

### 2. Authentication & Role-Based Access

#### 2a. Generate Base Auth

Generate the built-in Phoenix auth system:

```bash
mix phx.gen.auth Accounts User users
mix deps.get
mix ecto.migrate
```

This gives us registration, login, logout, email confirmation, and session management — all LiveView-based.

#### 2b. Add Role Field to Users

Create a migration to add a `role` field to the `users` table:

```bash
mix ecto.gen.migration add_role_to_users
```

```elixir
# In the generated migration:
def change do
  alter table(:users) do
    add :role, :string, null: false, default: "employee"
  end
end
```

#### 2c. User Roles

Define three roles with a clear hierarchy:

| Role         | Description                                                                 |
|--------------|-----------------------------------------------------------------------------|
| `employee`   | Default role. Can manage their own time entries, view assigned projects.     |
| `manager`    | Everything an employee can do, plus: create/edit projects and clients.       |
| `admin`      | Full access. Everything a manager can do, plus: manage users and assign roles. |

#### 2d. Update the User Schema

Add the role field and helpers to `lib/time_reg/accounts/user.ex`:

```elixir
schema "users" do
  # ... existing fields from phx.gen.auth ...
  field :role, :string, default: "employee"
  has_many :time_entries, TimeReg.Tracking.TimeEntry
  has_many :projects, TimeReg.Tracking.Project
  has_many :clients, TimeReg.Tracking.Client
  timestamps()
end

@roles ~w(employee manager admin)

def role_changeset(user, attrs) do
  user
  |> cast(attrs, [:role])
  |> validate_required([:role])
  |> validate_inclusion(:role, @roles)
end

# Role check helpers
def admin?(%__MODULE__{role: "admin"}), do: true
def admin?(_), do: false

def manager_or_above?(%__MODULE__{role: role}) when role in ~w(manager admin), do: true
def manager_or_above?(_), do: false

def employee?(%__MODULE__{role: "employee"}), do: true
def employee?(_), do: false
```

#### 2e. Authorization Plug

Create a reusable plug for route-level authorization at `lib/time_reg_web/plugs/authorize.ex`:

```elixir
defmodule TimeRegWeb.Plugs.Authorize do
  @moduledoc "Plug that verifies the current user has the required role."
  import Plug.Conn
  import Phoenix.Controller, only: [put_flash: 3, redirect: 2]

  def init(opts), do: opts

  def call(conn, roles) when is_list(roles) do
    user = conn.assigns[:current_user]

    if user && user.role in Enum.map(roles, &to_string/1) do
      conn
    else
      conn
      |> put_flash(:error, "You don't have permission to access this page.")
      |> redirect(to: "/dashboard")
      |> halt()
    end
  end
end
```

#### 2f. LiveView Authorization Hook

Create an `on_mount` hook for LiveView route protection at `lib/time_reg_web/live/hooks/authorize_hook.ex`:

```elixir
defmodule TimeRegWeb.Live.Hooks.AuthorizeHook do
  @moduledoc "LiveView on_mount hook for role-based access control."
  import Phoenix.LiveView
  import Phoenix.Component

  def on_mount(:admin_required, _params, _session, socket) do
    if TimeReg.Accounts.User.admin?(socket.assigns.current_user) do
      {:cont, socket}
    else
      {:halt, socket |> put_flash(:error, "Admin access required.") |> redirect(to: "/dashboard")}
    end
  end

  def on_mount(:manager_required, _params, _session, socket) do
    if TimeReg.Accounts.User.manager_or_above?(socket.assigns.current_user) do
      {:cont, socket}
    else
      {:halt, socket |> put_flash(:error, "Manager access required.") |> redirect(to: "/dashboard")}
    end
  end
end
```

#### 2g. Router Integration

Apply authorization in `router.ex` using both the plug and the LiveView hook:

```elixir
# All authenticated routes (existing)
scope "/", TimeRegWeb do
  pipe_through [:browser, :require_authenticated_user]

  # Employee-level routes (all logged-in users)
  live "/dashboard", DashboardLive
  live "/time-entries", TimeEntryLive.Index
  live "/time-entries/new", TimeEntryLive.Form, :new
  live "/time-entries/:id/edit", TimeEntryLive.Form, :edit
end

# Manager+ routes
scope "/", TimeRegWeb do
  pipe_through [:browser, :require_authenticated_user]

  live_session :manager_required,
    on_mount: [{TimeRegWeb.Live.Hooks.AuthorizeHook, :manager_required}] do
    live "/projects", ProjectLive.Index
    live "/projects/new", ProjectLive.Form, :new
    live "/projects/:id/edit", ProjectLive.Form, :edit
    live "/clients", ClientLive.Index
    live "/clients/new", ClientLive.Form, :new
    live "/clients/:id/edit", ClientLive.Form, :edit
    live "/reports", ReportLive
  end

  # Export also requires manager+
  get "/exports/time-entries", ExportController, :time_entries
end

# Admin-only routes
scope "/admin", TimeRegWeb do
  pipe_through [:browser, :require_authenticated_user]

  live_session :admin_required,
    on_mount: [{TimeRegWeb.Live.Hooks.AuthorizeHook, :admin_required}] do
    live "/users", Admin.UserLive.Index
    live "/users/:id/edit", Admin.UserLive.Edit
  end
end
```

#### 2h. Admin User Management Page (`/admin/users`)

Build a LiveView page for admins to manage users:

- **List all users** with columns: email, role, registration date, last login
- **Edit role** via inline dropdown (employee/manager/admin)
- **Deactivate users** (add `active` boolean to users table, soft-disable login)
- Admin cannot demote themselves (prevent locking yourself out)
- Show role badge next to each user (colored: green=admin, blue=manager, gray=employee)

#### 2i. Role-Aware Navigation

Update the sidebar/nav layout to conditionally show links based on role:

```elixir
# In your layout or nav component:
<.link :if={User.manager_or_above?(@current_user)} navigate={~p"/projects"}>
  Projects
</.link>
<.link :if={User.manager_or_above?(@current_user)} navigate={~p"/clients"}>
  Clients
</.link>
<.link :if={User.manager_or_above?(@current_user)} navigate={~p"/reports"}>
  Reports
</.link>
<.link :if={User.admin?(@current_user)} navigate={~p"/admin/users"}>
  User Management
</.link>
```

Employees see: **Dashboard, Time Entries** only.
Managers also see: **Projects, Clients, Reports**.
Admins additionally see: **User Management**.

#### 2j. Permission Matrix

| Action                        | Employee | Manager | Admin |
|-------------------------------|----------|---------|-------|
| Log own time entries          | ✅        | ✅       | ✅     |
| Edit/delete own time entries  | ✅        | ✅       | ✅     |
| View own reports              | ❌        | ✅       | ✅     |
| Create/edit projects          | ❌        | ✅       | ✅     |
| Create/edit clients           | ❌        | ✅       | ✅     |
| Archive projects              | ❌        | ✅       | ✅     |
| Export CSV                    | ❌        | ✅       | ✅     |
| Manage user roles             | ❌        | ❌       | ✅     |
| Deactivate users              | ❌        | ❌       | ✅     |

**Important:** Even though managers/admins have more features, all time entry data remains scoped to the individual user. No user can see another user's time entries.

### 3. Database Schema

Create the following Ecto schemas and migrations. All tables use SQLite-compatible types.

#### 3a. Clients

```bash
mix phx.gen.live Tracking Client clients \
  name:string \
  contact_email:string \
  active:boolean
```

Fields:
- `name` — string, required, unique
- `contact_email` — string, optional
- `active` — boolean, default `true`
- `user_id` — references users (belongs_to)
- timestamps

#### 3b. Projects

```bash
mix phx.gen.live Tracking Project projects \
  name:string \
  description:string \
  color:string \
  archived:boolean \
  client_id:references:clients
```

Fields:
- `name` — string, required
- `description` — string, optional
- `color` — string, hex color code for UI labels (e.g. `"#3B82F6"`)
- `archived` — boolean, default `false`
- `client_id` — references clients (belongs_to)
- `user_id` — references users (belongs_to)
- timestamps

#### 3c. Time Entries

```bash
mix phx.gen.live Tracking TimeEntry time_entries \
  description:string \
  date:date \
  start_time:time \
  end_time:time \
  duration_minutes:integer \
  billable:boolean \
  project_id:references:projects
```

Fields:
- `description` — string, optional (what you worked on)
- `date` — date, required
- `start_time` — time, optional (for clock-in/out style)
- `end_time` — time, optional
- `duration_minutes` — integer, required (auto-calculated from start/end, or manually entered)
- `billable` — boolean, default `true`
- `project_id` — references projects (belongs_to)
- `user_id` — references users (belongs_to)
- timestamps

#### 3d. Tags (optional, stretch goal)

A many-to-many relationship for categorizing time entries:

- `tags` table: `id`, `name`, `color`, `user_id`
- `time_entry_tags` join table: `time_entry_id`, `tag_id`

### 4. Ecto Schemas & Changesets

For each schema, implement:

- **Changeset validations:**
  - `Client`: validate `name` presence and uniqueness (scoped to user)
  - `Project`: validate `name` presence, validate `color` format with regex `~r/^#[0-9A-Fa-f]{6}$/`
  - `TimeEntry`: validate `date` and `duration_minutes` presence, validate `duration_minutes > 0`, auto-calculate `duration_minutes` from `start_time`/`end_time` if both are provided, validate `end_time > start_time`

- **Associations:**
  - `User` has_many `clients`, `projects`, `time_entries`
  - `Client` has_many `projects`, belongs_to `user`
  - `Project` belongs_to `client`, belongs_to `user`, has_many `time_entries`
  - `TimeEntry` belongs_to `project`, belongs_to `user`

- **Scope all queries to the current user** — never expose another user's data.

### 5. LiveView Pages

Build these LiveView pages. Use Phoenix Components and function components for reusable UI.

#### 5a. Dashboard (`/dashboard`) — Main landing page after login

- **Today's summary card:** Total hours logged today, count of entries
- **This week's summary:** Bar chart or simple table showing hours per day (Mon–Sun)
- **Running timer widget:** If a time entry has `start_time` but no `end_time`, show a live ticking timer using `Process.send_after` or `:timer.send_interval` to update every second
- **Quick entry form:** Inline form to add a new time entry without navigating away
- **Recent entries list:** Last 5 time entries with edit/delete actions

#### 5b. Time Entries Index (`/time-entries`)

- **List view** of all entries, grouped by date (most recent first)
- **Filters:** Date range picker, project dropdown, billable toggle
- **Inline editing:** Click an entry to edit it in-place (LiveView makes this seamless)
- **Bulk actions:** Select multiple entries, mark as billable/non-billable
- **Pagination** with `Flop` or simple offset-based pagination

#### 5c. Time Entry Form (`/time-entries/new`, `/time-entries/:id/edit`)

- **Two input modes**, toggled with a tab/switch:
  1. **Duration mode:** Pick date, project, enter hours:minutes manually
  2. **Timer mode:** Click "Start" to begin, "Stop" to end — calculates duration automatically
- **Project selector:** Dropdown grouped by client, showing project color dots
- **Description:** Text input with optional autocomplete from recent descriptions
- **Billable toggle**
- Live validation feedback (changeset errors displayed in real-time)

#### 5d. Projects CRUD (`/projects`)

- List all projects with client name, color badge, entry count
- Create/edit form with color picker (simple hex input or preset palette)
- Archive/unarchive toggle (soft delete)
- Show total hours logged per project

#### 5e. Clients CRUD (`/clients`)

- List all clients with project count, total hours
- Create/edit form
- Active/inactive toggle

#### 5f. Reports (`/reports`)

- **Filters:** Date range, client, project, billable status
- **Summary views:**
  - Hours per project (table + horizontal bar chart)
  - Hours per client
  - Hours per day/week/month (selectable granularity)
  - Billable vs non-billable breakdown
- **Export:** CSV download of filtered time entries
- Use LiveView streams or async assigns for large datasets

### 6. The Live Timer Feature

This is the core real-time feature. Implement it as a LiveView component:

```elixir
# In the LiveView:
def mount(_params, _session, socket) do
  if connected?(socket) do
    # Check for any running timer (entry with start_time but no end_time)
    case Tracking.get_running_timer(socket.assigns.current_user) do
      nil -> {:ok, assign(socket, running_timer: nil, elapsed: 0)}
      entry ->
        :timer.send_interval(1000, self(), :tick)
        elapsed = Time.diff(Time.utc_now(), entry.start_time, :second)
        {:ok, assign(socket, running_timer: entry, elapsed: elapsed)}
    end
  else
    {:ok, assign(socket, running_timer: nil, elapsed: 0)}
  end
end

def handle_info(:tick, socket) do
  {:noreply, update(socket, :elapsed, &(&1 + 1))}
end
```

- "Start Timer" creates a `TimeEntry` with `start_time = now`, `end_time = nil`
- "Stop Timer" sets `end_time = now`, calculates `duration_minutes`
- Only one timer can run at a time per user
- Timer persists across page navigation (it's in the DB)
- Show the running timer in the top nav bar as a sticky component

### 7. CSV Export

Implement a controller endpoint (not LiveView) for file downloads:

```elixir
# In router.ex
get "/exports/time-entries", ExportController, :time_entries

# ExportController
def time_entries(conn, params) do
  entries = Tracking.list_time_entries(conn.assigns.current_user, params)

  csv_content =
    entries
    |> Enum.map(fn e ->
      [e.date, e.project.name, e.project.client.name,
       e.description, e.duration_minutes, e.billable]
    end)
    |> CSV.encode(headers: ["Date", "Project", "Client",
                            "Description", "Minutes", "Billable"])
    |> Enum.join()

  conn
  |> put_resp_content_type("text/csv")
  |> put_resp_header("content-disposition", "attachment; filename=\"time-entries.csv\"")
  |> send_resp(200, csv_content)
end
```

Use the `nimble_csv` or `csv` library.

### 8. UI & Styling Guidelines

Use the default Phoenix/Tailwind setup. Aim for a clean, functional design:

- **Color palette:** Use project colors as accent dots/badges throughout the UI
- **Layout:** Sidebar navigation (Dashboard, Time Entries, Projects, Clients, Reports) + top bar with user menu and running timer
- **Responsive:** Sidebar collapses to hamburger on mobile
- **Components to extract:**
  - `TimeEntryCard` — displays a single entry with project color, duration, description
  - `TimerDisplay` — shows `HH:MM:SS` with start/stop button
  - `ProjectBadge` — colored dot + project name
  - `DurationInput` — custom input that accepts "1h30m", "90m", "1.5h" formats and converts to minutes
  - `DateRangePicker` — two date inputs with "This Week", "This Month", "Last Month" presets
- Use `Phoenix.Component` for all reusable components
- Use LiveView Streams (`stream/3`) for the time entries list to handle large lists efficiently

### 9. Business Logic & Context Module

The `Tracking` context module (`lib/time_reg/tracking.ex`) should include:

```elixir
# Core CRUD (auto-generated, then customize)
def list_time_entries(user, filters \\ %{})
def get_time_entry!(user, id)
def create_time_entry(user, attrs)
def update_time_entry(user, entry, attrs)
def delete_time_entry(user, entry)

# Timer operations
def start_timer(user, project_id, description \\ "")
def stop_timer(user)
def get_running_timer(user)

# Reporting queries
def hours_by_project(user, date_range)
def hours_by_client(user, date_range)
def hours_by_day(user, date_range)
def daily_summary(user, date)
def weekly_summary(user, week_start_date)

# All queries MUST be scoped to user:
# from e in TimeEntry, where: e.user_id == ^user.id
```

### 10. Testing

Write tests for:

- **Schema tests:** Changeset validations, duration calculation, role validation
- **Context tests:** CRUD operations, timer start/stop, report queries, user-scoping (verify user A can't see user B's data)
- **Authorization tests:**
  - Employee cannot access `/projects`, `/clients`, `/reports`, `/admin/users`
  - Manager can access projects/clients/reports but not `/admin/users`
  - Admin can access all routes including `/admin/users`
  - Admin cannot demote their own role
  - Role changes persist correctly
- **LiveView tests:** Use `Phoenix.LiveViewTest` — test form submission, timer start/stop, filter interactions, verify nav links are role-conditional
- Run with `mix test`

### 11. Seeds

Create `priv/repo/seeds.exs` with:

- 3 demo users:
  - Admin: `admin@example.com` / `password123456` (role: `admin`)
  - Manager: `manager@example.com` / `password123456` (role: `manager`)
  - Employee: `demo@example.com` / `password123456` (role: `employee`)
- 3 clients
- 5-6 projects across those clients (with different colors)
- 30+ time entries spread across the last 2 weeks for each user, varying durations, projects, and billable status

### 12. Additional Dependencies

Add these to `mix.exs`:

```elixir
defp deps do
  [
    # ... existing deps ...
    {:nimble_csv, "~> 1.2"},   # CSV export
    {:flop, "~> 0.25"},        # Optional: filtering/sorting/pagination
    {:flop_phoenix, "~> 0.23"} # Optional: LiveView components for Flop
  ]
end
```

---

## Quality Checklist

Before considering this complete, verify:

- [ ] `mix compile --warnings-as-errors` passes with zero warnings
- [ ] `mix test` — all tests pass
- [ ] `mix format` — code is formatted
- [ ] All DB queries are scoped to `current_user`
- [ ] Role-based routes are protected (employee can't access manager/admin pages)
- [ ] Admin user management page works (list users, change roles, deactivate)
- [ ] Admin cannot demote themselves
- [ ] Nav sidebar shows/hides links based on user role
- [ ] Timer persists across page reloads
- [ ] Timer displays in nav bar across all pages
- [ ] CSV export works with filters applied
- [ ] Forms show real-time validation errors
- [ ] Responsive layout works on mobile viewport
- [ ] Seeds run cleanly on fresh database (3 users with different roles)
- [ ] No N+1 queries (use preloads)
- [ ] SQLite WAL mode is enabled for concurrent reads

---

## Project Structure (Expected)

```
time_reg/
├── lib/
│   ├── time_reg/
│   │   ├── accounts/          # User auth (generated + role extensions)
│   │   │   ├── user.ex        # Includes role field + role helpers
│   │   │   └── user_token.ex
│   │   ├── tracking/          # Business domain
│   │   │   ├── client.ex
│   │   │   ├── project.ex
│   │   │   └── time_entry.ex
│   │   ├── tracking.ex        # Context module
│   │   └── repo.ex
│   ├── time_reg_web/
│   │   ├── plugs/
│   │   │   └── authorize.ex   # Role-based authorization plug
│   │   ├── components/
│   │   │   ├── core_components.ex
│   │   │   ├── timer_display.ex
│   │   │   └── layouts/
│   │   ├── live/
│   │   │   ├── hooks/
│   │   │   │   └── authorize_hook.ex  # LiveView on_mount RBAC hook
│   │   │   ├── admin/
│   │   │   │   ├── user_live/
│   │   │   │   │   ├── index.ex       # User management (admin only)
│   │   │   │   │   └── edit.ex
│   │   │   ├── dashboard_live.ex
│   │   │   ├── time_entry_live/
│   │   │   │   ├── index.ex
│   │   │   │   ├── show.ex
│   │   │   │   └── form_component.ex
│   │   │   ├── project_live/
│   │   │   ├── client_live/
│   │   │   └── report_live.ex
│   │   ├── controllers/
│   │   │   └── export_controller.ex
│   │   └── router.ex
├── priv/
│   └── repo/
│       ├── migrations/
│       └── seeds.exs
└── test/
```

---

## Execution Order

Follow this sequence when building:

1. Bootstrap the Phoenix project with SQLite
2. Generate base auth and add role field migration
3. Implement role helpers, authorization plug, and LiveView auth hook
4. Create migrations and schemas (clients → projects → time_entries)
5. Build the Tracking context with CRUD + queries
6. Set up router with role-based route groups
7. Build LiveView pages (start with time entries, then projects/clients)
8. Build the admin user management page
9. Implement the live timer feature
10. Build the dashboard
11. Build the reports page
12. Add CSV export
13. Write tests (including authorization tests)
14. Create seeds (3 users with different roles)
15. Polish UI, add responsive layout, role-conditional nav