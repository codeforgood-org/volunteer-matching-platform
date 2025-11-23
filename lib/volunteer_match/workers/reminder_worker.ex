defmodule VolunteerMatch.Workers.ReminderWorker do
  @moduledoc """
  Sends reminders for upcoming volunteer opportunities.
  """
  use Oban.Worker, queue: :default, max_attempts: 3

  alias VolunteerMatch.{Repo, Opportunities, Mailer}
  alias VolunteerMatch.Emails.OpportunityEmail
  import Ecto.Query

  @impl Oban.Worker
  def perform(%Oban.Job{}) do
    tomorrow = Date.add(Date.utc_today(), 1)

    # Find applications for opportunities starting tomorrow
    applications =
      from(a in Opportunities.Application,
        join: o in assoc(a, :opportunity),
        join: v in assoc(a, :volunteer),
        join: u in assoc(v, :user),
        where: a.status == :accepted,
        where: o.start_date == ^tomorrow,
        preload: [volunteer: {v, user: u}, opportunity: o]
      )
      |> Repo.all()

    Enum.each(applications, fn application ->
      OpportunityEmail.reminder_email(application)
      |> Mailer.deliver()
    end)

    {:ok, %{reminders_sent: length(applications)}}
  end
end
