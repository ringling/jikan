# Jikan Features Documentation

## Time Entry Management

### Creating Time Entries

Users can create time entries in multiple ways:

1. **Timer Mode** (Dashboard)
   - Start/stop timer with real-time elapsed time display
   - Pause/resume functionality for breaks
   - Automatic duration calculation

2. **Quick Add** (Dashboard)
   - Manual entry with date, project, and duration
   - Optional description and billable flag
   - Hourly rate auto-populated from project/client

3. **Full Form** (Time Entries → New)
   - All fields available including start/end times
   - Manual duration entry or automatic calculation
   - Pause duration tracking for breaks

### Duration and Pause Tracking

- **Gross Duration**: Total time from start to end
- **Pause Duration**: Time spent on breaks (lunch, meetings, etc.)
- **Net Duration**: Actual working time (gross - pause)
- All displays show net duration with pause time indicated separately
- Billing calculations use net duration only

### Hourly Rate Hierarchy

The system uses a three-level hierarchy for determining hourly rates:

1. **Entry Level**: Rate can be set per individual time entry
2. **Project Level**: Default rate for all entries in a project
3. **Client Level**: Default rate for all projects under a client

Priority: Entry Rate → Project Rate → Client Default Rate

### Billing Calculations

- **Automatic Calculation**: Total amount = Net Duration × Hourly Rate
- **Non-billable Entries**: Can track time without billing (internal work, meetings)
- **Real-time Updates**: Amount updates immediately when rate or duration changes
- **Decimal Precision**: All amounts rounded to 2 decimal places

## Dashboard Features

### Today's Summary
- Total hours worked today
- Number of entries created
- Visual progress indicators

### This Week's Hours
- Daily breakdown with progress bars
- Visual representation of work patterns
- 8-hour workday reference line

### Weekly Statistics
- Total hours for current week
- Number of entries
- Comparison with previous weeks

### Monthly Overview
- Total hours worked this month
- Total billable revenue
- Number of billable entries

### Recent Entries
- Last 5 time entries with quick access
- Shows project, duration, and billable status
- Quick edit and delete actions

### Running Timer
- Real-time elapsed time display
- Pause/resume controls
- Visual status indicator

## Filtering and Search

### Time Entries Filters
- **Company/Client**: Filter by client
- **Year**: Annual view
- **Month**: Monthly breakdown
- **Week**: ISO week numbers
- **Combination**: All filters work together

### Filter Persistence
- Filters saved in URL for bookmarking
- Active filter badges when panel collapsed
- Entry counter shows filtered results

## Data Export

### CSV Export
- Export filtered time entries
- Smart filename based on active filters
- Includes all relevant fields:
  - Date, Company, Project, Description
  - Start/End times, Duration, Pause duration
  - Billable status, Hourly rate, Total amount
  - Week and Month indicators

## Project Management

### Projects (Manager/Admin only)
- Create and edit projects
- Assign to clients
- Set project-specific hourly rates
- Color coding for visual identification
- Archive inactive projects

### Clients (Manager/Admin only)
- Manage client information
- Set default hourly rates
- Contact information
- Active/inactive status

## User Roles and Permissions

### Employee Role
- View and manage own time entries
- Access dashboard and reports
- Use timer and quick entry
- Export own data

### Manager Role
- All employee permissions
- Create and manage projects
- Create and manage clients
- View team statistics (planned)

### Admin Role
- All manager permissions
- User management (planned)
- System configuration
- Access to all data

## User Interface

### Responsive Design
- Mobile-first approach
- Progressive disclosure (hide non-essential columns on mobile)
- Touch-friendly controls
- Optimized padding for mobile screens

### DaisyUI Components
- Professional themed components
- Consistent visual language
- Dark/light theme support
- Accessible design patterns

### Real-time Updates
- LiveView-powered reactivity
- No page refreshes needed
- Instant feedback on actions
- WebSocket connections for live updates

## Technical Features

### PostgreSQL Database
- Reliable data storage
- ACID compliance
- Advanced querying capabilities
- Docker containerization

### Phoenix LiveView
- Server-rendered reactive UI
- No JavaScript framework required
- Real-time updates over WebSockets
- Reduced client-side complexity

### Docker Deployment
- Containerized application
- PostgreSQL included
- Easy deployment with docker-compose
- Environment-based configuration

## Planned Features

### User Management
- Admin panel for user administration
- Role assignment interface
- User activity logs
- Password reset by admin

### Team Features
- Team time tracking overview
- Project allocation views
- Team productivity metrics
- Resource planning

### Reporting
- Custom report builder
- PDF export option
- Email reports
- Advanced analytics

### Integrations
- Calendar sync
- Slack notifications
- Invoice generation
- API for third-party tools