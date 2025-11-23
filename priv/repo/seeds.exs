# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     VolunteerMatch.Repo.insert!(%VolunteerMatch.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.

alias VolunteerMatch.{Repo, Accounts, Volunteers, NGOs, Opportunities}
alias VolunteerMatch.Accounts.User
alias VolunteerMatch.Volunteers.Volunteer
alias VolunteerMatch.NGOs.NGO
alias VolunteerMatch.Opportunities.Opportunity

# Clear existing data (optional, for development only)
if Mix.env() == :dev do
  Repo.delete_all(Opportunity)
  Repo.delete_all(Volunteer)
  Repo.delete_all(NGO)
  Repo.delete_all(User)
end

IO.puts("Seeding database...")

# Create Admin User
{:ok, admin} =
  Accounts.register_user(%{
    email: "admin@volunteermatch.org",
    password: "Admin123!",
    first_name: "Admin",
    last_name: "User",
    role: :admin
  })
  |> case do
    {:ok, user} -> {:ok, user}
    {:error, _} -> {:ok, Accounts.get_user_by_email("admin@volunteermatch.org")}
  end

IO.puts("✓ Created admin user: admin@volunteermatch.org / Admin123!")

# Create Sample NGOs
ngo_data = [
  %{
    email: "contact@redcross.org",
    password: "RedCross123!",
    first_name: "Red",
    last_name: "Cross",
    role: :ngo,
    ngo: %{
      name: "American Red Cross",
      description: "The American Red Cross prevents and alleviates human suffering in the face of emergencies by mobilizing the power of volunteers and the generosity of donors.",
      mission: "To prevent and relieve suffering through emergency assistance, disaster relief, and education.",
      website: "https://www.redcross.org",
      causes: ["Disaster Relief", "Health & Medicine", "Community Development"],
      address: "2025 E Street NW",
      city: "Washington",
      state: "DC",
      country: "USA",
      postal_code: "20006",
      latitude: 38.8977,
      longitude: -77.0365,
      phone: "(202) 303-5000",
      year_founded: 1881,
      organization_size: :large,
      is_verified: true
    }
  },
  %{
    email: "volunteer@habitatforhumanity.org",
    password: "Habitat123!",
    first_name: "Habitat",
    last_name: "Humanity",
    role: :ngo,
    ngo: %{
      name: "Habitat for Humanity",
      description: "Habitat for Humanity brings people together to build homes, communities and hope.",
      mission: "Seeking to put God's love into action, Habitat for Humanity brings people together to build homes, communities and hope.",
      website: "https://www.habitat.org",
      causes: ["Housing & Homelessness", "Community Development", "Construction"],
      address: "285 Peachtree Center Ave NE",
      city: "Atlanta",
      state: "GA",
      country: "USA",
      postal_code: "30303",
      latitude: 33.7590,
      longitude: -84.3880,
      phone: "(800) 422-4828",
      year_founded: 1976,
      organization_size: :large,
      is_verified: true
    }
  },
  %{
    email: "info@localfoodbank.org",
    password: "FoodBank123!",
    first_name: "Local",
    last_name: "FoodBank",
    role: :ngo,
    ngo: %{
      name: "City Food Bank",
      description: "Fighting hunger and providing nutritious food to families in need.",
      mission: "To end hunger in our community by providing access to nutritious food and promoting self-sufficiency.",
      website: "https://www.cityfoodbank.org",
      causes: ["Hunger & Poverty", "Community Development", "Children & Youth"],
      address: "123 Main Street",
      city: "San Francisco",
      state: "CA",
      country: "USA",
      postal_code: "94102",
      latitude: 37.7749,
      longitude: -122.4194,
      phone: "(415) 555-0100",
      year_founded: 2005,
      organization_size: :medium,
      is_verified: true
    }
  },
  %{
    email: "contact@oceanguardians.org",
    password: "Ocean123!",
    first_name: "Ocean",
    last_name: "Guardians",
    role: :ngo,
    ngo: %{
      name: "Ocean Guardians",
      description: "Protecting marine life and ocean ecosystems through conservation and education.",
      mission: "To protect and restore ocean ecosystems for future generations.",
      website: "https://www.oceanguardians.org",
      causes: ["Environment", "Wildlife & Animals", "Education"],
      address: "456 Beach Blvd",
      city: "San Diego",
      state: "CA",
      country: "USA",
      postal_code: "92101",
      latitude: 32.7157,
      longitude: -117.1611,
      phone: "(619) 555-0200",
      year_founded: 2010,
      organization_size: :small,
      is_verified: false
    }
  }
]

ngos =
  Enum.map(ngo_data, fn data ->
    {:ok, user} =
      Accounts.register_user(%{
        email: data.email,
        password: data.password,
        first_name: data.first_name,
        last_name: data.last_name,
        role: data.role
      })

    {:ok, ngo} =
      NGOs.create_ngo(
        Map.merge(data.ngo, %{user_id: user.id})
      )

    IO.puts("✓ Created NGO: #{ngo.name}")
    ngo
  end)

# Create Sample Volunteers
volunteer_data = [
  %{
    email: "john.doe@email.com",
    password: "John123!",
    first_name: "John",
    last_name: "Doe",
    role: :volunteer,
    volunteer: %{
      bio: "Passionate about helping my community and making a positive impact.",
      skills: ["Construction", "Teaching", "Event Planning"],
      interests: ["Education", "Environment", "Community"],
      causes: ["Community Development", "Children & Youth", "Education"],
      address: "789 Oak Avenue",
      city: "San Francisco",
      state: "CA",
      country: "USA",
      postal_code: "94103",
      latitude: 37.7749,
      longitude: -122.4194,
      max_distance: 25,
      hours_per_week: 10,
      experience_level: :intermediate,
      languages: ["English", "Spanish"]
    }
  },
  %{
    email: "jane.smith@email.com",
    password: "Jane123!",
    first_name: "Jane",
    last_name: "Smith",
    role: :volunteer,
    volunteer: %{
      bio: "Experienced volunteer with a background in healthcare and education.",
      skills: ["Healthcare", "Counseling", "Administration"],
      interests: ["Health", "Education", "Seniors"],
      causes: ["Health & Medicine", "Seniors", "Community Development"],
      address: "321 Pine Street",
      city: "San Francisco",
      state: "CA",
      country: "USA",
      postal_code: "94104",
      latitude: 37.7849,
      longitude: -122.4094,
      max_distance: 15,
      hours_per_week: 5,
      experience_level: :advanced,
      languages: ["English"]
    }
  },
  %{
    email: "mike.johnson@email.com",
    password: "Mike123!",
    first_name: "Mike",
    last_name: "Johnson",
    role: :volunteer,
    volunteer: %{
      bio: "New to volunteering and eager to make a difference!",
      skills: ["Social Media", "Writing", "Photography"],
      interests: ["Animals", "Environment", "Arts"],
      causes: ["Wildlife & Animals", "Environment", "Arts & Culture"],
      address: "555 Market Street",
      city: "San Francisco",
      state: "CA",
      country: "USA",
      postal_code: "94105",
      latitude: 37.7649,
      longitude: -122.4294,
      max_distance: 30,
      hours_per_week: 8,
      experience_level: :beginner,
      languages: ["English"]
    }
  }
]

volunteers =
  Enum.map(volunteer_data, fn data ->
    {:ok, user} =
      Accounts.register_user(%{
        email: data.email,
        password: data.password,
        first_name: data.first_name,
        last_name: data.last_name,
        role: data.role
      })

    {:ok, volunteer} =
      Volunteers.create_volunteer(
        Map.merge(data.volunteer, %{user_id: user.id})
      )

    IO.puts("✓ Created volunteer: #{user.first_name} #{user.last_name}")
    volunteer
  end)

# Create Sample Opportunities
opportunity_data = [
  %{
    ngo: Enum.at(ngos, 0),
    title: "Disaster Relief Volunteer",
    description: "Help provide disaster relief services to affected communities. Assist with emergency response, shelter operations, and recovery efforts.",
    causes: ["Disaster Relief", "Community Development"],
    skills_required: ["First Aid", "Communication", "Problem Solving"],
    address: "2025 E Street NW",
    city: "Washington",
    state: "DC",
    country: "USA",
    postal_code: "20006",
    latitude: 38.8977,
    longitude: -77.0365,
    is_remote: false,
    start_date: Date.add(Date.utc_today(), 7),
    end_date: Date.add(Date.utc_today(), 37),
    application_deadline: Date.add(Date.utc_today(), 5),
    time_commitment: "Flexible, 4-8 hours per week",
    frequency: :weekly,
    duration_hours: 8,
    volunteers_needed: 10,
    experience_level: :beginner,
    min_age: 18,
    requirements: ["Background check required", "Attend orientation"],
    benefits: ["Training provided", "T-shirt", "Certificate"],
    status: :published,
    featured: true,
    priority: :high
  },
  %{
    ngo: Enum.at(ngos, 1),
    title: "Home Building Project",
    description: "Join us in building affordable homes for families in need. No construction experience required - we'll train you!",
    causes: ["Housing & Homelessness", "Community Development"],
    skills_required: ["Construction", "Teamwork"],
    address: "285 Peachtree Center Ave NE",
    city: "Atlanta",
    state: "GA",
    country: "USA",
    postal_code: "30303",
    latitude: 33.7590,
    longitude: -84.3880,
    is_remote: false,
    start_date: Date.add(Date.utc_today(), 14),
    end_date: Date.add(Date.utc_today(), 90),
    application_deadline: Date.add(Date.utc_today(), 10),
    time_commitment: "Saturdays, 8 hours",
    frequency: :weekly,
    duration_hours: 8,
    volunteers_needed: 20,
    experience_level: :any,
    min_age: 16,
    requirements: ["Closed-toe shoes", "Bring water"],
    benefits: ["Lunch provided", "Meet amazing people", "Make a real difference"],
    status: :published,
    featured: true,
    priority: :high
  },
  %{
    ngo: Enum.at(ngos, 2),
    title: "Food Sorting and Distribution",
    description: "Help sort and distribute food to families facing hunger. Great opportunity for groups and individuals.",
    causes: ["Hunger & Poverty", "Community Development"],
    skills_required: [],
    address: "123 Main Street",
    city: "San Francisco",
    state: "CA",
    country: "USA",
    postal_code: "94102",
    latitude: 37.7749,
    longitude: -122.4194,
    is_remote: false,
    start_date: Date.add(Date.utc_today(), 3),
    end_date: Date.add(Date.utc_today(), 60),
    application_deadline: Date.add(Date.utc_today(), 2),
    time_commitment: "Flexible shifts available",
    frequency: :flexible,
    duration_hours: 4,
    volunteers_needed: 15,
    experience_level: :any,
    min_age: 14,
    requirements: ["Comfortable standing for long periods"],
    benefits: ["Flexible scheduling", "Community impact"],
    status: :published,
    featured: false,
    priority: :medium
  },
  %{
    ngo: Enum.at(ngos, 3),
    title: "Beach Cleanup Event",
    description: "Join us for a monthly beach cleanup to protect marine life and keep our oceans beautiful. Fun for all ages!",
    causes: ["Environment", "Wildlife & Animals"],
    skills_required: [],
    address: "456 Beach Blvd",
    city: "San Diego",
    state: "CA",
    country: "USA",
    postal_code: "92101",
    latitude: 32.7157,
    longitude: -117.1611,
    is_remote: false,
    start_date: Date.add(Date.utc_today(), 21),
    application_deadline: Date.add(Date.utc_today(), 19),
    time_commitment: "One Saturday morning per month",
    frequency: :monthly,
    duration_hours: 3,
    volunteers_needed: 30,
    experience_level: :any,
    min_age: 8,
    requirements: ["Bring reusable gloves if possible"],
    benefits: ["Meet ocean lovers", "Free t-shirt", "Refreshments provided"],
    status: :published,
    featured: false,
    priority: :low
  },
  %{
    ngo: Enum.at(ngos, 0),
    title: "Virtual Tutoring for Students",
    description: "Help students with homework and educational support via video calls. Work from anywhere!",
    causes: ["Education", "Children & Youth"],
    skills_required: ["Teaching", "Communication", "Patience"],
    city: "Remote",
    state: "Remote",
    country: "USA",
    is_remote: true,
    is_virtual: true,
    start_date: Date.add(Date.utc_today(), 10),
    end_date: Date.add(Date.utc_today(), 120),
    application_deadline: Date.add(Date.utc_today(), 7),
    time_commitment: "2-4 hours per week, flexible schedule",
    frequency: :weekly,
    duration_hours: 3,
    volunteers_needed: 25,
    experience_level: :intermediate,
    min_age: 18,
    requirements: ["Reliable internet", "Quiet space", "Background check"],
    benefits: ["Work from home", "Flexible hours", "Make a lasting impact"],
    status: :published,
    featured: true,
    priority: :high
  }
]

opportunities =
  Enum.map(opportunity_data, fn data ->
    ngo = data.ngo
    data = Map.delete(data, :ngo)

    {:ok, opportunity} =
      Opportunities.create_opportunity(
        Map.merge(data, %{ngo_id: ngo.id})
      )

    IO.puts("✓ Created opportunity: #{opportunity.title}")
    opportunity
  end)

IO.puts("\n✅ Database seeded successfully!")
IO.puts("\nTest Credentials:")
IO.puts("================")
IO.puts("Admin: admin@volunteermatch.org / Admin123!")
IO.puts("\nNGOs:")
IO.puts("- contact@redcross.org / RedCross123!")
IO.puts("- volunteer@habitatforhumanity.org / Habitat123!")
IO.puts("- info@localfoodbank.org / FoodBank123!")
IO.puts("- contact@oceanguardians.org / Ocean123!")
IO.puts("\nVolunteers:")
IO.puts("- john.doe@email.com / John123!")
IO.puts("- jane.smith@email.com / Jane123!")
IO.puts("- mike.johnson@email.com / Mike123!")
IO.puts("\nCreated:")
IO.puts("- #{length(ngos)} NGOs")
IO.puts("- #{length(volunteers)} Volunteers")
IO.puts("- #{length(opportunities)} Opportunities")
