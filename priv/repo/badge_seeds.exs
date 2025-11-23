# Script for seeding badges and achievements
alias VolunteerMatch.Repo
alias VolunteerMatch.Gamification.{Badge, Achievement}

IO.puts("Seeding badges and achievements...")

# Volunteer Hours Badges
badges = [
  %{
    name: "first_hour",
    description: "Completed your first volunteer hour",
    icon: "⏱️",
    category: :volunteer_hours,
    rarity: :common,
    points: 10,
    criteria: %{hours: 1}
  },
  %{
    name: "10_hours_starter",
    description: "Completed 10 volunteer hours",
    icon: "🌟",
    category: :volunteer_hours,
    rarity: :common,
    points: 25,
    criteria: %{hours: 10}
  },
  %{
    name: "50_hours_committed",
    description: "Completed 50 volunteer hours",
    icon: "💪",
    category: :volunteer_hours,
    rarity: :uncommon,
    points: 75,
    criteria: %{hours: 50}
  },
  %{
    name: "100_hours_veteran",
    description: "Completed 100 volunteer hours",
    icon: "🏅",
    category: :volunteer_hours,
    rarity: :rare,
    points: 150,
    criteria: %{hours: 100}
  },
  %{
    name: "250_hours_champion",
    description: "Completed 250 volunteer hours",
    icon: "🏆",
    category: :volunteer_hours,
    rarity: :epic,
    points: 300,
    criteria: %{hours: 250}
  },
  %{
    name: "500_hours_hero",
    description: "Completed 500 volunteer hours - You're a true hero!",
    icon: "👑",
    category: :volunteer_hours,
    rarity: :legendary,
    points: 500,
    criteria: %{hours: 500}
  },

  # Opportunity Completion Badges
  %{
    name: "first_opportunity",
    description: "Completed your first volunteer opportunity",
    icon: "🎯",
    category: :opportunities_completed,
    rarity: :common,
    points: 20,
    criteria: %{opportunities: 1}
  },
  %{
    name: "5_opportunities_active",
    description: "Completed 5 volunteer opportunities",
    icon: "🚀",
    category: :opportunities_completed,
    rarity: :common,
    points: 50,
    criteria: %{opportunities: 5}
  },
  %{
    name: "10_opportunities_regular",
    description: "Completed 10 volunteer opportunities",
    icon: "⭐",
    category: :opportunities_completed,
    rarity: :uncommon,
    points: 100,
    criteria: %{opportunities: 10}
  },
  %{
    name: "25_opportunities_expert",
    description: "Completed 25 volunteer opportunities",
    icon: "💎",
    category: :opportunities_completed,
    rarity: :rare,
    points: 200,
    criteria: %{opportunities: 25}
  },
  %{
    name: "50_opportunities_legend",
    description: "Completed 50 volunteer opportunities - Legendary!",
    icon: "🌟",
    category: :opportunities_completed,
    rarity: :epic,
    points: 400,
    criteria: %{opportunities: 50}
  },

  # Rating Badges
  %{
    name: "highly_rated",
    description: "Maintained a 4.5+ star rating",
    icon: "⭐⭐⭐⭐⭐",
    category: :skills,
    rarity: :rare,
    points: 150,
    criteria: %{rating: 4.5}
  },
  %{
    name: "perfect_rating",
    description: "Achieved a perfect 5.0 star rating",
    icon: "✨",
    category: :skills,
    rarity: :legendary,
    points: 300,
    criteria: %{rating: 5.0}
  },

  # Social Badges
  %{
    name: "social_butterfly",
    description: "Followed 10 users",
    icon: "🦋",
    category: :social,
    rarity: :common,
    points: 30,
    criteria: %{following: 10}
  },
  %{
    name: "popular",
    description: "Got 50 followers",
    icon: "🌟",
    category: :social,
    rarity: :uncommon,
    points: 75,
    criteria: %{followers: 50}
  },
  %{
    name: "influencer",
    description: "Got 100 followers",
    icon: "💫",
    category: :social,
    rarity: :rare,
    points: 150,
    criteria: %{followers: 100}
  },

  # Impact Badges
  %{
    name: "community_builder",
    description: "Volunteered in 3 different causes",
    icon: "🏘️",
    category: :impact,
    rarity: :uncommon,
    points: 100,
    criteria: %{causes: 3}
  },
  %{
    name: "changemaker",
    description: "Volunteered in 5 different causes",
    icon: "🌍",
    category: :impact,
    rarity: :rare,
    points: 200,
    criteria: %{causes: 5}
  },

  # Special Badges
  %{
    name: "early_adopter",
    description: "One of the first users on the platform",
    icon: "🚀",
    category: :special,
    rarity: :epic,
    points: 250,
    criteria: %{special: "early_adopter"}
  },
  %{
    name: "weekend_warrior",
    description: "Completed 10 weekend volunteer opportunities",
    icon: "💪",
    category: :special,
    rarity: :uncommon,
    points: 100,
    criteria: %{weekend_opportunities: 10}
  }
]

Enum.each(badges, fn badge_attrs ->
  %Badge{}
  |> Badge.changeset(badge_attrs)
  |> Repo.insert!()
  IO.puts("✓ Created badge: #{badge_attrs.name}")
end)

# Achievements
achievements = [
  %{
    name: "Getting Started",
    description: "Complete your first volunteer opportunity",
    icon: "🎯",
    tier: :bronze,
    points: 50,
    progress_max: 1,
    unlock_criteria: %{opportunities_completed: 1}
  },
  %{
    name: "Volunteer Regular",
    description: "Complete 10 volunteer opportunities",
    icon: "📅",
    tier: :silver,
    points: 100,
    progress_max: 10,
    unlock_criteria: %{opportunities_completed: 10}
  },
  %{
    name: "Dedicated Volunteer",
    description: "Complete 25 volunteer opportunities",
    icon: "💪",
    tier: :gold,
    points: 250,
    progress_max: 25,
    unlock_criteria: %{opportunities_completed: 25}
  },
  %{
    name: "Volunteer Champion",
    description: "Complete 50 volunteer opportunities",
    icon: "👑",
    tier: :platinum,
    points: 500,
    progress_max: 50,
    unlock_criteria: %{opportunities_completed: 50}
  },
  %{
    name: "Time Contributor",
    description: "Volunteer for 100 total hours",
    icon: "⏰",
    tier: :silver,
    points: 150,
    progress_max: 100,
    unlock_criteria: %{hours: 100}
  },
  %{
    name: "Time Champion",
    description: "Volunteer for 500 total hours",
    icon: "⏱️",
    tier: :platinum,
    points: 750,
    progress_max: 500,
    unlock_criteria: %{hours: 500}
  },
  %{
    name: "Community Favorite",
    description: "Receive 10 five-star reviews",
    icon: "⭐",
    tier: :gold,
    points: 300,
    progress_max: 10,
    unlock_criteria: %{five_star_reviews: 10}
  },
  %{
    name: "Cause Diversity",
    description: "Volunteer for 5 different causes",
    icon: "🌈",
    tier: :silver,
    points: 200,
    progress_max: 5,
    unlock_criteria: %{different_causes: 5}
  },
  %{
    name: "Social Connector",
    description: "Get 25 followers",
    icon: "🤝",
    tier: :bronze,
    points: 75,
    progress_max: 25,
    unlock_criteria: %{followers: 25}
  },
  %{
    name: "Social Influencer",
    description: "Get 100 followers",
    icon: "📢",
    tier: :gold,
    points: 300,
    progress_max: 100,
    unlock_criteria: %{followers: 100}
  }
]

Enum.each(achievements, fn achievement_attrs ->
  %Achievement{}
  |> Achievement.changeset(achievement_attrs)
  |> Repo.insert!()
  IO.puts("✓ Created achievement: #{achievement_attrs.name}")
end)

IO.puts("\n✅ Badges and achievements seeded successfully!")
IO.puts("Created:")
IO.puts("- #{length(badges)} Badges")
IO.puts("- #{length(achievements)} Achievements")
