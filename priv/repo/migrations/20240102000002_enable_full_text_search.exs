defmodule VolunteerMatch.Repo.Migrations.EnableFullTextSearch do
  use Ecto.Migration

  def up do
    # Enable pg_trgm extension for trigram similarity
    execute "CREATE EXTENSION IF NOT EXISTS pg_trgm"
    execute "CREATE EXTENSION IF NOT EXISTS unaccent"

    # Create GIN indexes for full-text search on opportunities
    execute """
    CREATE INDEX opportunities_title_trgm_idx ON opportunities
    USING GIN (title gin_trgm_ops)
    """

    execute """
    CREATE INDEX opportunities_description_trgm_idx ON opportunities
    USING GIN (description gin_trgm_ops)
    """

    execute """
    CREATE INDEX opportunities_search_idx ON opportunities
    USING GIN (to_tsvector('english', title || ' ' || description))
    """

    # Create GIN indexes for NGOs
    execute """
    CREATE INDEX ngos_name_trgm_idx ON ngos
    USING GIN (name gin_trgm_ops)
    """

    execute """
    CREATE INDEX ngos_mission_trgm_idx ON ngos
    USING GIN (mission gin_trgm_ops)
    """

    execute """
    CREATE INDEX ngos_search_idx ON ngos
    USING GIN (to_tsvector('english', name || ' ' || mission))
    """

    # Create GIN indexes for volunteers (searching by skills and causes)
    execute """
    CREATE INDEX volunteers_skills_gin_idx ON volunteers
    USING GIN (skills)
    """

    execute """
    CREATE INDEX volunteers_causes_gin_idx ON volunteers
    USING GIN (causes)
    """
  end

  def down do
    # Drop indexes
    execute "DROP INDEX IF EXISTS opportunities_title_trgm_idx"
    execute "DROP INDEX IF EXISTS opportunities_description_trgm_idx"
    execute "DROP INDEX IF EXISTS opportunities_search_idx"
    execute "DROP INDEX IF EXISTS ngos_name_trgm_idx"
    execute "DROP INDEX IF EXISTS ngos_mission_trgm_idx"
    execute "DROP INDEX IF EXISTS ngos_search_idx"
    execute "DROP INDEX IF EXISTS volunteers_skills_gin_idx"
    execute "DROP INDEX IF EXISTS volunteers_causes_gin_idx"

    # Extensions can be left in place as they don't harm
  end
end
