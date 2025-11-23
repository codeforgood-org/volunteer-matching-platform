defmodule VolunteerMatch.Emails.OpportunityEmail do
  import Swoosh.Email

  alias VolunteerMatch.Mailer

  @from_email Application.compile_env(:volunteer_match, :from_email, "noreply@volunteermatch.org")

  def new_match_email(volunteer, opportunity, match_score) do
    new()
    |> to({volunteer.user.first_name <> " " <> volunteer.user.last_name, volunteer.user.email})
    |> from(@from_email)
    |> subject("New Volunteer Opportunity Match!")
    |> html_body("""
    <h1>Hi #{volunteer.user.first_name}!</h1>
    <p>We found a great volunteer opportunity for you!</p>

    <h2>#{opportunity.title}</h2>
    <p>#{opportunity.description}</p>

    <p><strong>Match Score:</strong> #{match_score}%</p>
    <p><strong>Location:</strong> #{opportunity.city}, #{opportunity.state}</p>
    <p><strong>Start Date:</strong> #{opportunity.start_date}</p>

    <p><a href="https://volunteermatch.org/opportunities/#{opportunity.id}">View Opportunity</a></p>

    <p>Happy volunteering!<br>The VolunteerMatch Team</p>
    """)
    |> text_body("""
    Hi #{volunteer.user.first_name}!

    We found a great volunteer opportunity for you!

    #{opportunity.title}
    #{opportunity.description}

    Match Score: #{match_score}%
    Location: #{opportunity.city}, #{opportunity.state}
    Start Date: #{opportunity.start_date}

    View Opportunity: https://volunteermatch.org/opportunities/#{opportunity.id}

    Happy volunteering!
    The VolunteerMatch Team
    """)
  end

  def application_received_email(application) do
    volunteer = application.volunteer
    opportunity = application.opportunity

    new()
    |> to({volunteer.user.first_name <> " " <> volunteer.user.last_name, volunteer.user.email})
    |> from(@from_email)
    |> subject("Application Received - #{opportunity.title}")
    |> html_body("""
    <h1>Application Received!</h1>
    <p>Hi #{volunteer.user.first_name},</p>

    <p>We've received your application for <strong>#{opportunity.title}</strong>.</p>

    <p>The organization will review your application and get back to you soon.</p>

    <p><a href="https://volunteermatch.org/applications/#{application.id}">View Application</a></p>

    <p>Thank you for volunteering!<br>The VolunteerMatch Team</p>
    """)
  end

  def application_accepted_email(application) do
    volunteer = application.volunteer
    opportunity = application.opportunity

    new()
    |> to({volunteer.user.first_name <> " " <> volunteer.user.last_name, volunteer.user.email})
    |> from(@from_email)
    |> subject("Application Accepted - #{opportunity.title}")
    |> html_body("""
    <h1>Congratulations!</h1>
    <p>Hi #{volunteer.user.first_name},</p>

    <p>Your application for <strong>#{opportunity.title}</strong> has been accepted!</p>

    <p><strong>What's Next:</strong></p>
    <ul>
      <li>Check your calendar for the opportunity start date: #{opportunity.start_date}</li>
      <li>Review the opportunity details and requirements</li>
      <li>Contact the organization if you have any questions</li>
    </ul>

    <p><a href="https://volunteermatch.org/opportunities/#{opportunity.id}">View Opportunity Details</a></p>

    <p>We're excited to have you make a difference!<br>The VolunteerMatch Team</p>
    """)
  end

  def reminder_email(application) do
    volunteer = application.volunteer
    opportunity = application.opportunity

    new()
    |> to({volunteer.user.first_name <> " " <> volunteer.user.last_name, volunteer.user.email})
    |> from(@from_email)
    |> subject("Reminder: #{opportunity.title} starts tomorrow!")
    |> html_body("""
    <h1>Upcoming Opportunity Reminder</h1>
    <p>Hi #{volunteer.user.first_name},</p>

    <p>This is a friendly reminder that your volunteer opportunity <strong>#{opportunity.title}</strong> starts tomorrow!</p>

    <p><strong>Details:</strong></p>
    <ul>
      <li><strong>Date:</strong> #{opportunity.start_date}</li>
      <li><strong>Location:</strong> #{opportunity.address}, #{opportunity.city}, #{opportunity.state}</li>
      <li><strong>Duration:</strong> #{opportunity.duration_hours} hours</li>
    </ul>

    <p><a href="https://volunteermatch.org/opportunities/#{opportunity.id}">View Full Details</a></p>

    <p>See you there!<br>The VolunteerMatch Team</p>
    """)
  end

  def new_application_notification(ngo, application) do
    volunteer = application.volunteer
    opportunity = application.opportunity

    new()
    |> to({ngo.name, ngo.email})
    |> from(@from_email)
    |> subject("New Volunteer Application - #{opportunity.title}")
    |> html_body("""
    <h1>New Volunteer Application</h1>
    <p>Hi #{ngo.name},</p>

    <p>You have a new volunteer application for <strong>#{opportunity.title}</strong>.</p>

    <p><strong>Volunteer:</strong> #{volunteer.user.first_name} #{volunteer.user.last_name}</p>
    <p><strong>Message:</strong></p>
    <p>#{application.message}</p>

    <p><a href="https://volunteermatch.org/applications/#{application.id}">Review Application</a></p>

    <p>Best regards,<br>The VolunteerMatch Team</p>
    """)
  end
end
