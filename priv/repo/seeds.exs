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

# Create clients for each user
users = [admin, manager, employee]
colors = ["#3B82F6", "#10B981", "#F59E0B", "#EF4444", "#8B5CF6", "#EC4899"]

for user <- users do
  # Create clients
  acme_corp = Repo.insert!(%Client{
    name: "ACME Corporation",
    contact_email: "contact@acme.com",
    active: true,
    user_id: user.id
  })

  tech_startup = Repo.insert!(%Client{
    name: "Tech Startup Inc",
    contact_email: "hello@techstartup.io",
    active: true,
    user_id: user.id
  })

  consulting_co = Repo.insert!(%Client{
    name: "Consulting Co",
    contact_email: "info@consulting.com",
    active: true,
    user_id: user.id
  })

  # Create projects
  website_redesign = Repo.insert!(%Project{
    name: "Website Redesign",
    description: "Complete redesign of corporate website",
    color: Enum.at(colors, 0),
    archived: false,
    client_id: acme_corp.id,
    user_id: user.id
  })

  mobile_app = Repo.insert!(%Project{
    name: "Mobile App Development",
    description: "iOS and Android app for customer portal",
    color: Enum.at(colors, 1),
    archived: false,
    client_id: acme_corp.id,
    user_id: user.id
  })

  api_integration = Repo.insert!(%Project{
    name: "API Integration",
    description: "Integrate third-party APIs",
    color: Enum.at(colors, 2),
    archived: false,
    client_id: tech_startup.id,
    user_id: user.id
  })

  data_migration = Repo.insert!(%Project{
    name: "Data Migration",
    description: "Migrate legacy data to new system",
    color: Enum.at(colors, 3),
    archived: false,
    client_id: tech_startup.id,
    user_id: user.id
  })

  security_audit = Repo.insert!(%Project{
    name: "Security Audit",
    description: "Comprehensive security assessment",
    color: Enum.at(colors, 4),
    archived: false,
    client_id: consulting_co.id,
    user_id: user.id
  })

  training_program = Repo.insert!(%Project{
    name: "Training Program",
    description: "Employee training and documentation",
    color: Enum.at(colors, 5),
    archived: false,
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
        
        Repo.insert!(%TimeEntry{
          description: description,
          date: date,
          start_time: start_time,
          end_time: end_time,
          duration_minutes: duration,
          billable: :rand.uniform(100) > 20, # 80% billable
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
