# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     Jikan.Repo.insert!(%Jikan.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.

alias Jikan.Repo
alias Jikan.Accounts.User
alias Jikan.Tracking.{Client, Project, TimeEntry}

# Create demo users
admin = Repo.insert!(%User{
  email: "admin@example.com",
  hashed_password: Bcrypt.hash_pwd_salt("password123456"),
  role: "admin",
  confirmed_at: DateTime.utc_now() |> DateTime.truncate(:second)
})

manager = Repo.insert!(%User{
  email: "manager@example.com",
  hashed_password: Bcrypt.hash_pwd_salt("password123456"),
  role: "manager",
  confirmed_at: DateTime.utc_now() |> DateTime.truncate(:second)
})

employee = Repo.insert!(%User{
  email: "demo@example.com",
  hashed_password: Bcrypt.hash_pwd_salt("password123456"),
  role: "employee",
  confirmed_at: DateTime.utc_now() |> DateTime.truncate(:second)
})

IO.puts "Created users:"
IO.puts "  admin@example.com / password123456 (admin)"
IO.puts "  manager@example.com / password123456 (manager)"
IO.puts "  demo@example.com / password123456 (employee)"
IO.puts ""
IO.puts "Hourly rates setup:"
IO.puts "  ACME Corporation: 850.00 DKK/hour (client default)"
IO.puts "    → Website Redesign: 950.00 DKK/hour (project override)"
IO.puts "    → Mobile App Development: 1200.00 DKK/hour (project override)"
IO.puts "  Tech Startup Inc: 900.00 DKK/hour (client default)"
IO.puts "    → API Integration: 900.00 DKK/hour (uses client default)"
IO.puts "    → Data Migration: 800.00 DKK/hour (project override)"
IO.puts "  Consulting Co: 1100.00 DKK/hour (client default)"
IO.puts "    → Security Audit: 1400.00 DKK/hour (project override)"
IO.puts "    → Training Program: 1100.00 DKK/hour (uses client default)"

# Create clients for each user
users = [admin, manager, employee]
colors = ["#3B82F6", "#10B981", "#F59E0B", "#EF4444", "#8B5CF6", "#EC4899"]

for user <- users do
  # Create clients with default hourly rates
  acme_corp = Repo.insert!(%Client{
    name: "ACME Corporation",
    contact_email: "contact@acme.com",
    active: true,
    default_hourly_rate: Decimal.new("850.00"),
    user_id: user.id
  })

  tech_startup = Repo.insert!(%Client{
    name: "Tech Startup Inc",
    contact_email: "hello@techstartup.io",
    active: true,
    default_hourly_rate: Decimal.new("900.00"),
    user_id: user.id
  })

  consulting_co = Repo.insert!(%Client{
    name: "Consulting Co",
    contact_email: "info@consulting.com",
    active: true,
    default_hourly_rate: Decimal.new("1100.00"),
    user_id: user.id
  })

  # Create projects with varying hourly rate strategies
  website_redesign = Repo.insert!(%Project{
    name: "Website Redesign",
    description: "Complete redesign of corporate website",
    color: Enum.at(colors, 0),
    archived: false,
    hourly_rate: Decimal.new("950.00"), # Premium rate for design work
    client_id: acme_corp.id,
    user_id: user.id
  })

  mobile_app = Repo.insert!(%Project{
    name: "Mobile App Development",
    description: "iOS and Android app for customer portal",
    color: Enum.at(colors, 1),
    archived: false,
    hourly_rate: Decimal.new("1200.00"), # High rate for mobile development
    client_id: acme_corp.id,
    user_id: user.id
  })

  api_integration = Repo.insert!(%Project{
    name: "API Integration",
    description: "Integrate third-party APIs",
    color: Enum.at(colors, 2),
    archived: false,
    # No hourly_rate set - will use client default (900.00)
    client_id: tech_startup.id,
    user_id: user.id
  })

  data_migration = Repo.insert!(%Project{
    name: "Data Migration",
    description: "Migrate legacy data to new system",
    color: Enum.at(colors, 3),
    archived: false,
    hourly_rate: Decimal.new("800.00"), # Lower rate for routine data work
    client_id: tech_startup.id,
    user_id: user.id
  })

  security_audit = Repo.insert!(%Project{
    name: "Security Audit",
    description: "Comprehensive security assessment",
    color: Enum.at(colors, 4),
    archived: false,
    hourly_rate: Decimal.new("1400.00"), # Premium rate for security work
    client_id: consulting_co.id,
    user_id: user.id
  })

  training_program = Repo.insert!(%Project{
    name: "Training Program",
    description: "Employee training and documentation",
    color: Enum.at(colors, 5),
    archived: false,
    # No hourly_rate set - will use client default (1100.00)
    client_id: consulting_co.id,
    user_id: user.id
  })

  # Create time entries for the last 2 weeks
  projects = [website_redesign, mobile_app, api_integration, data_migration, security_audit, training_program]
  descriptions = [
    "Frontend development",
    "Backend API work",
    "Database optimization",
    "Code review",
    "Testing and QA",
    "Documentation",
    "Client meeting",
    "Sprint planning",
    "Bug fixing",
    "Feature implementation",
    "Deployment preparation",
    "Performance tuning"
  ]

  today = Date.utc_today()
  
  for days_ago <- 0..13 do
    date = Date.add(today, -days_ago)
    
    # Skip weekends for more realistic data
    if Date.day_of_week(date) not in [6, 7] do
      # Create 2-5 entries per day
      num_entries = :rand.uniform(4) + 1
      
      for _ <- 1..num_entries do
        project = Enum.random(projects)
        description = Enum.random(descriptions)
        
        # Random duration between 30 and 180 minutes
        duration = (:rand.uniform(6) + 1) * 30
        
        # Random start time between 8am and 5pm
        hour = :rand.uniform(9) + 7
        minute = :rand.uniform(4) * 15
        start_time = ~T[08:00:00] |> Time.add(hour * 3600 + minute * 60, :second)
        end_time = Time.add(start_time, duration * 60, :second)
        
        # Determine hourly rate (project rate or client default)
        acme_corp_id = acme_corp.id
        tech_startup_id = tech_startup.id
        consulting_co_id = consulting_co.id
        
        hourly_rate = project.hourly_rate || 
                      (case project.client_id do
                         ^acme_corp_id -> Decimal.new("850.00")
                         ^tech_startup_id -> Decimal.new("900.00")
                         ^consulting_co_id -> Decimal.new("1100.00")
                         _ -> nil
                       end)
        
        billable = :rand.uniform(100) > 20 # 80% billable
        
        # Calculate total amount if billable and rate exists
        total_amount = if billable && hourly_rate do
          hours = Decimal.div(Decimal.new(duration), Decimal.new(60))
          Decimal.mult(hours, hourly_rate) |> Decimal.round(2)
        else
          Decimal.new(0)
        end
        
        Repo.insert!(%TimeEntry{
          description: description,
          date: date,
          start_time: start_time,
          end_time: end_time,
          duration_minutes: duration,
          billable: billable,
          hourly_rate: hourly_rate,
          total_amount: total_amount,
          project_id: project.id,
          user_id: user.id
        })
      end
    end
  end
  
  IO.puts "Created sample data for #{user.email}"
end

IO.puts "\nSeed data created successfully!"
IO.puts "You can log in with any of the demo accounts above."
