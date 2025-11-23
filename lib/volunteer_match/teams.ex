defmodule VolunteerMatch.Teams do
  @moduledoc """
  The Teams context handles team/group volunteering functionality.
  """

  import Ecto.Query
  alias VolunteerMatch.{Repo, Teams.Team, Teams.TeamMember, Volunteers.Volunteer}

  @doc """
  Creates a new team with the creator as the leader.
  """
  def create_team(attrs, leader_id) do
    %Team{}
    |> Team.changeset(Map.put(attrs, "leader_id", leader_id))
    |> Repo.insert()
    |> case do
      {:ok, team} ->
        # Automatically add the leader as a team member
        add_member(team.id, leader_id, "leader")
        {:ok, team}

      error ->
        error
    end
  end

  @doc """
  Updates a team.
  """
  def update_team(%Team{} = team, attrs) do
    team
    |> Team.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a team.
  """
  def delete_team(%Team{} = team) do
    Repo.delete(team)
  end

  @doc """
  Gets a single team.
  """
  def get_team!(id) do
    Team
    |> Repo.get!(id)
    |> Repo.preload([:leader, :team_members, :members])
  end

  @doc """
  Lists all teams.
  """
  def list_teams(filters \\\\ %{}) do
    Team
    |> apply_team_filters(filters)
    |> Repo.all()
    |> Repo.preload([:leader, :team_members])
  end

  @doc """
  Lists teams a volunteer is a member of.
  """
  def list_volunteer_teams(volunteer_id) do
    from(t in Team,
      join: tm in TeamMember,
      on: tm.team_id == t.id,
      where: tm.volunteer_id == ^volunteer_id and tm.status == "active",
      preload: [:leader, :team_members]
    )
    |> Repo.all()
  end

  @doc """
  Adds a member to a team.
  """
  def add_member(team_id, volunteer_id, role \\\\ "member") do
    team = get_team!(team_id)

    # Check if team is full
    member_count = count_active_members(team_id)

    if member_count >= team.max_members do
      {:error, :team_full}
    else
      %TeamMember{}
      |> TeamMember.changeset(%{
        team_id: team_id,
        volunteer_id: volunteer_id,
        role: role,
        status: if(team.is_public, do: "active", else: "pending"),
        joined_at: if(team.is_public, do: DateTime.utc_now(), else: nil)
      })
      |> Repo.insert()
    end
  end

  @doc """
  Invites a volunteer to join a team.
  """
  def invite_member(team_id, volunteer_id) do
    add_member(team_id, volunteer_id, "member")
  end

  @doc """
  Accepts a team invitation.
  """
  def accept_invitation(team_id, volunteer_id) do
    team_member = get_team_member!(team_id, volunteer_id)

    team_member
    |> TeamMember.accept_changeset()
    |> Repo.update()
  end

  @doc """
  Removes a member from a team.
  """
  def remove_member(team_id, volunteer_id) do
    team_member = get_team_member!(team_id, volunteer_id)

    team_member
    |> TeamMember.remove_changeset()
    |> Repo.update()
  end

  @doc """
  Updates a member's role in the team.
  """
  def update_member_role(team_id, volunteer_id, new_role) do
    team_member = get_team_member!(team_id, volunteer_id)

    team_member
    |> TeamMember.changeset(%{role: new_role})
    |> Repo.update()
  end

  @doc """
  Checks if a volunteer is a member of a team.
  """
  def member?(team_id, volunteer_id) do
    from(tm in TeamMember,
      where: tm.team_id == ^team_id and tm.volunteer_id == ^volunteer_id and tm.status == "active"
    )
    |> Repo.exists?()
  end

  @doc """
  Checks if a volunteer is the leader of a team.
  """
  def leader?(team_id, volunteer_id) do
    from(tm in TeamMember,
      where: tm.team_id == ^team_id and tm.volunteer_id == ^volunteer_id and tm.role == "leader"
    )
    |> Repo.exists?()
  end

  @doc """
  Gets active members of a team.
  """
  def get_team_members(team_id) do
    from(tm in TeamMember,
      where: tm.team_id == ^team_id and tm.status == "active",
      preload: [:volunteer]
    )
    |> Repo.all()
  end

  @doc """
  Counts active members in a team.
  """
  def count_active_members(team_id) do
    from(tm in TeamMember,
      where: tm.team_id == ^team_id and tm.status == "active",
      select: count(tm.id)
    )
    |> Repo.one()
  end

  @doc """
  Gets team statistics.
  """
  def get_team_stats(team_id) do
    team = get_team!(team_id)

    applications_count =
      from(a in VolunteerMatch.Opportunities.Application,
        where: a.team_id == ^team_id,
        select: count(a.id)
      )
      |> Repo.one()

    completed_count =
      from(a in VolunteerMatch.Opportunities.Application,
        where: a.team_id == ^team_id and a.status == :completed,
        select: count(a.id)
      )
      |> Repo.one()

    total_hours =
      from(a in VolunteerMatch.Opportunities.Application,
        where: a.team_id == ^team_id and a.status == :completed,
        select: sum(a.volunteer_hours)
      )
      |> Repo.one() || 0

    %{
      member_count: count_active_members(team_id),
      max_members: team.max_members,
      applications_count: applications_count,
      completed_count: completed_count,
      total_hours: total_hours
    }
  end

  # Private functions

  defp get_team_member!(team_id, volunteer_id) do
    from(tm in TeamMember,
      where: tm.team_id == ^team_id and tm.volunteer_id == ^volunteer_id
    )
    |> Repo.one!()
  end

  defp apply_team_filters(query, filters) do
    Enum.reduce(filters, query, fn
      {:is_public, value}, query ->
        where(query, [t], t.is_public == ^value)

      {:team_type, value}, query ->
        where(query, [t], t.team_type == ^value)

      {:leader_id, value}, query ->
        where(query, [t], t.leader_id == ^value)

      _, query ->
        query
    end)
  end
end
