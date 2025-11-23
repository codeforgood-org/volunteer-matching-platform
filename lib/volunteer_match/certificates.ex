defmodule VolunteerMatch.Certificates do
  @moduledoc """
  The Certificates context provides certificate generation for completed volunteer work.
  """

  alias VolunteerMatch.{Repo, Opportunities.Application, Volunteers.Volunteer}

  @doc """
  Generates a certificate for a completed application.
  """
  def generate_certificate(application_id) do
    application =
      Application
      |> Repo.get!(application_id)
      |> Repo.preload([
        :volunteer,
        volunteer: :user,
        opportunity: :ngo,
        opportunity: [ngo: :user]
      ])

    if application.status != :completed do
      {:error, :application_not_completed}
    else
      certificate_data = build_certificate_data(application)
      generate_pdf(certificate_data)
    end
  end

  @doc """
  Generates a summary certificate for all volunteer work.
  """
  def generate_summary_certificate(volunteer_id) do
    volunteer =
      Volunteer
      |> Repo.get!(volunteer_id)
      |> Repo.preload([:user, applications: [opportunity: :ngo]])

    completed_applications =
      Enum.filter(volunteer.applications, &(&1.status == :completed))

    if Enum.empty?(completed_applications) do
      {:error, :no_completed_work}
    else
      certificate_data = build_summary_certificate_data(volunteer, completed_applications)
      generate_pdf(certificate_data)
    end
  end

  # Private functions

  defp build_certificate_data(application) do
    %{
      type: :single,
      volunteer_name: "#{application.volunteer.user.first_name} #{application.volunteer.user.last_name}",
      opportunity_title: application.opportunity.title,
      ngo_name: application.opportunity.ngo.name,
      hours: application.volunteer_hours || 0,
      completion_date: application.completed_at,
      certificate_id: generate_certificate_id(application.id)
    }
  end

  defp build_summary_certificate_data(volunteer, completed_applications) do
    total_hours = Enum.reduce(completed_applications, 0, &(&1.volunteer_hours + &2))

    opportunities_by_ngo =
      Enum.group_by(completed_applications, & &1.opportunity.ngo.name)
      |> Enum.map(fn {ngo, apps} ->
        %{
          ngo: ngo,
          count: length(apps),
          hours: Enum.reduce(apps, 0, &(&1.volunteer_hours + &2))
        }
      end)

    %{
      type: :summary,
      volunteer_name: "#{volunteer.user.first_name} #{volunteer.user.last_name}",
      total_hours: total_hours,
      total_opportunities: length(completed_applications),
      organizations: opportunities_by_ngo,
      member_since: volunteer.inserted_at,
      certificate_id: generate_certificate_id(volunteer.id)
    }
  end

  defp generate_pdf(certificate_data) do
    html = generate_html(certificate_data)

    # For production, you would use a library like ChromicPDF or Wkhtmltopdf
    # For now, we'll return the HTML content
    {:ok, html}
  end

  defp generate_html(%{type: :single} = data) do
    """
    <!DOCTYPE html>
    <html>
    <head>
      <meta charset="UTF-8">
      <title>Volunteer Certificate</title>
      <style>
        @page { size: A4 landscape; margin: 0; }
        body {
          font-family: 'Georgia', serif;
          margin: 0;
          padding: 60px;
          background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
          color: #333;
        }
        .certificate {
          background: white;
          padding: 80px;
          border: 20px solid #f0f0f0;
          box-shadow: 0 0 30px rgba(0,0,0,0.3);
          text-align: center;
        }
        .header {
          font-size: 48px;
          color: #667eea;
          margin-bottom: 20px;
          font-weight: bold;
          text-transform: uppercase;
          letter-spacing: 3px;
        }
        .subheader {
          font-size: 24px;
          color: #666;
          margin-bottom: 40px;
        }
        .recipient {
          font-size: 36px;
          color: #333;
          margin: 30px 0;
          font-weight: bold;
        }
        .details {
          font-size: 20px;
          line-height: 1.8;
          margin: 40px 0;
          color: #555;
        }
        .highlight {
          color: #667eea;
          font-weight: bold;
        }
        .signature {
          margin-top: 60px;
          display: flex;
          justify-content: space-around;
        }
        .signature-block {
          text-align: center;
        }
        .signature-line {
          border-top: 2px solid #333;
          width: 250px;
          margin: 10px auto;
        }
        .footer {
          margin-top: 40px;
          font-size: 14px;
          color: #999;
        }
        .seal {
          width: 100px;
          height: 100px;
          border-radius: 50%;
          border: 3px solid #667eea;
          display: flex;
          align-items: center;
          justify-content: center;
          margin: 0 auto 20px;
          font-size: 40px;
        }
      </style>
    </head>
    <body>
      <div class="certificate">
        <div class="seal">🏆</div>
        <div class="header">Certificate of Appreciation</div>
        <div class="subheader">Volunteer Service Recognition</div>

        <div class="recipient">#{data.volunteer_name}</div>

        <div class="details">
          Has successfully completed volunteer service for<br>
          <span class="highlight">#{data.opportunity_title}</span><br>
          with<br>
          <span class="highlight">#{data.ngo_name}</span><br>
          contributing a total of<br>
          <span class="highlight">#{data.hours} hours</span><br>
          of dedicated service
        </div>

        <div class="details">
          Completion Date: <span class="highlight">#{format_date(data.completion_date)}</span>
        </div>

        <div class="signature">
          <div class="signature-block">
            <div class="signature-line"></div>
            <div>#{data.ngo_name}</div>
            <div style="font-size: 14px; color: #999;">Organization Representative</div>
          </div>
          <div class="signature-block">
            <div class="signature-line"></div>
            <div>VolunteerMatch Platform</div>
            <div style="font-size: 14px; color: #999;">Platform Administrator</div>
          </div>
        </div>

        <div class="footer">
          Certificate ID: #{data.certificate_id}<br>
          Generated on #{format_date(DateTime.utc_now())}
        </div>
      </div>
    </body>
    </html>
    """
  end

  defp generate_html(%{type: :summary} = data) do
    organizations_html =
      data.organizations
      |> Enum.map(fn org ->
        "<li>#{org.ngo}: #{org.count} opportunities, #{org.hours} hours</li>"
      end)
      |> Enum.join("\n")

    """
    <!DOCTYPE html>
    <html>
    <head>
      <meta charset="UTF-8">
      <title>Volunteer Service Summary Certificate</title>
      <style>
        @page { size: A4; margin: 0; }
        body {
          font-family: 'Georgia', serif;
          margin: 0;
          padding: 40px;
          background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
          color: #333;
        }
        .certificate {
          background: white;
          padding: 60px;
          border: 15px solid #f0f0f0;
          box-shadow: 0 0 30px rgba(0,0,0,0.3);
          text-align: center;
        }
        .header {
          font-size: 42px;
          color: #667eea;
          margin-bottom: 20px;
          font-weight: bold;
          text-transform: uppercase;
          letter-spacing: 3px;
        }
        .recipient {
          font-size: 32px;
          color: #333;
          margin: 30px 0;
          font-weight: bold;
        }
        .summary {
          font-size: 18px;
          line-height: 1.8;
          margin: 30px 0;
          color: #555;
        }
        .highlight {
          color: #667eea;
          font-weight: bold;
          font-size: 24px;
        }
        .organizations {
          text-align: left;
          max-width: 600px;
          margin: 30px auto;
          font-size: 16px;
        }
        .organizations ul {
          list-style-type: none;
          padding: 0;
        }
        .organizations li {
          padding: 10px;
          border-bottom: 1px solid #eee;
        }
        .seal {
          width: 80px;
          height: 80px;
          border-radius: 50%;
          border: 3px solid #667eea;
          display: flex;
          align-items: center;
          justify-content: center;
          margin: 0 auto 20px;
          font-size: 36px;
        }
        .footer {
          margin-top: 40px;
          font-size: 12px;
          color: #999;
        }
      </style>
    </head>
    <body>
      <div class="certificate">
        <div class="seal">⭐</div>
        <div class="header">Volunteer Service Summary</div>

        <div class="recipient">#{data.volunteer_name}</div>

        <div class="summary">
          Has contributed an outstanding<br>
          <span class="highlight">#{data.total_hours} hours</span><br>
          across<br>
          <span class="highlight">#{data.total_opportunities} volunteer opportunities</span><br>
          since becoming a member on<br>
          <span class="highlight">#{format_date(data.member_since)}</span>
        </div>

        <div class="organizations">
          <h3 style="text-align: center; color: #667eea;">Organizations Served:</h3>
          <ul>
            #{organizations_html}
          </ul>
        </div>

        <div class="summary" style="margin-top: 40px;">
          Your dedication and commitment to making a difference in your community<br>
          is truly commendable and greatly appreciated.
        </div>

        <div class="footer">
          Certificate ID: #{data.certificate_id}<br>
          Generated on #{format_date(DateTime.utc_now())}<br>
          VolunteerMatch Platform
        </div>
      </div>
    </body>
    </html>
    """
  end

  defp format_date(nil), do: "N/A"

  defp format_date(date) do
    Calendar.strftime(date, "%B %d, %Y")
  end

  defp generate_certificate_id(id) do
    hash = :crypto.hash(:sha256, id) |> Base.encode16() |> String.slice(0..15)
    "CERT-#{hash}"
  end
end
