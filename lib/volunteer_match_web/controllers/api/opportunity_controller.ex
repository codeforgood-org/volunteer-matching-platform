defmodule VolunteerMatchWeb.API.OpportunityController do
  use VolunteerMatchWeb, :controller

  alias VolunteerMatch.Opportunities
  alias VolunteerMatch.Opportunities.Opportunity

  action_fallback VolunteerMatchWeb.FallbackController

  def index(conn, params) do
    opportunities = Opportunities.list_opportunities(params)
    render(conn, :index, opportunities: opportunities)
  end

  def create(conn, %{"opportunity" => opportunity_params}) do
    user = Guardian.Plug.current_resource(conn)

    case user.role do
      :ngo ->
        ngo = VolunteerMatch.NGOs.get_ngo_by_user_id(user.id)

        opportunity_params = Map.put(opportunity_params, "ngo_id", ngo.id)

        with {:ok, %Opportunity{} = opportunity} <-
               Opportunities.create_opportunity(opportunity_params) do
          conn
          |> put_status(:created)
          |> render(:show, opportunity: opportunity)
        end

      _ ->
        conn
        |> put_status(:forbidden)
        |> json(%{error: "Only NGOs can create opportunities"})
    end
  end

  def show(conn, %{"id" => id}) do
    opportunity = Opportunities.get_opportunity!(id)
    Opportunities.increment_view_count(opportunity)
    render(conn, :show, opportunity: opportunity)
  end

  def update(conn, %{"id" => id, "opportunity" => opportunity_params}) do
    opportunity = Opportunities.get_opportunity!(id)
    user = Guardian.Plug.current_resource(conn)
    ngo = VolunteerMatch.NGOs.get_ngo_by_user_id(user.id)

    if opportunity.ngo_id == ngo.id do
      with {:ok, %Opportunity{} = opportunity} <-
             Opportunities.update_opportunity(opportunity, opportunity_params) do
        render(conn, :show, opportunity: opportunity)
      end
    else
      conn
      |> put_status(:forbidden)
      |> json(%{error: "You can only update your own opportunities"})
    end
  end

  def delete(conn, %{"id" => id}) do
    opportunity = Opportunities.get_opportunity!(id)
    user = Guardian.Plug.current_resource(conn)
    ngo = VolunteerMatch.NGOs.get_ngo_by_user_id(user.id)

    if opportunity.ngo_id == ngo.id do
      with {:ok, %Opportunity{}} <- Opportunities.delete_opportunity(opportunity) do
        send_resp(conn, :no_content, "")
      end
    else
      conn
      |> put_status(:forbidden)
      |> json(%{error: "You can only delete your own opportunities"})
    end
  end

  def apply(conn, %{"opportunity_id" => opportunity_id} = params) do
    user = Guardian.Plug.current_resource(conn)
    volunteer = VolunteerMatch.Volunteers.get_volunteer_by_user_id(user.id)

    application_params =
      params
      |> Map.put("volunteer_id", volunteer.id)
      |> Map.put("opportunity_id", opportunity_id)

    with {:ok, application} <- Opportunities.create_application(application_params) do
      conn
      |> put_status(:created)
      |> json(%{
        message: "Application submitted successfully",
        application_id: application.id
      })
    end
  end

  def nearby(conn, %{"lat" => lat, "lng" => lng} = params) do
    latitude = String.to_float(lat)
    longitude = String.to_float(lng)
    radius = Map.get(params, "radius", "25") |> String.to_integer()

    results = Opportunities.search_opportunities_near(latitude, longitude, radius, params)

    render(conn, :nearby, results: results)
  end
end
