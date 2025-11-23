defmodule VolunteerMatchWeb.Router do
  use VolunteerMatchWeb, :router

  import VolunteerMatchWeb.UserAuth

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {VolunteerMatchWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :fetch_current_user
  end

  pipeline :api do
    plug :accepts, ["json"]
    plug VolunteerMatchWeb.APIAuthPlug
  end

  pipeline :api_authenticated do
    plug Guardian.Plug.Pipeline,
      module: VolunteerMatch.Guardian,
      error_handler: VolunteerMatchWeb.AuthErrorHandler

    plug Guardian.Plug.VerifyHeader
    plug Guardian.Plug.EnsureAuthenticated
    plug Guardian.Plug.LoadResource
  end

  scope "/", VolunteerMatchWeb do
    pipe_through :browser

    get "/", PageController, :home

    # Public routes
    live "/opportunities", OpportunityLive.Index, :index
    live "/opportunities/:id", OpportunityLive.Show, :show
    live "/ngos", NGOLive.Index, :index
    live "/ngos/:id", NGOLive.Show, :show
  end

  # Authentication routes
  scope "/", VolunteerMatchWeb do
    pipe_through [:browser, :redirect_if_user_is_authenticated]

    live_session :redirect_if_user_is_authenticated,
      on_mount: [{VolunteerMatchWeb.UserAuth, :redirect_if_user_is_authenticated}] do
      live "/users/register", UserRegistrationLive, :new
      live "/users/log_in", UserLoginLive, :new
      live "/users/reset_password", UserForgotPasswordLive, :new
      live "/users/reset_password/:token", UserResetPasswordLive, :edit
    end

    post "/users/log_in", UserSessionController, :create
  end

  # Authenticated routes
  scope "/", VolunteerMatchWeb do
    pipe_through [:browser, :require_authenticated_user]

    live_session :require_authenticated_user,
      on_mount: [{VolunteerMatchWeb.UserAuth, :ensure_authenticated}] do
      live "/dashboard", DashboardLive.Index, :index
      live "/users/settings", UserSettingsLive, :edit
      live "/users/settings/confirm_email/:token", UserSettingsLive, :confirm_email

      # Volunteer routes
      live "/volunteer/profile", VolunteerLive.Profile, :edit
      live "/volunteer/opportunities", VolunteerLive.Opportunities, :index
      live "/volunteer/applications", VolunteerLive.Applications, :index
      live "/volunteer/matches", VolunteerLive.Matches, :index
      live "/volunteer/messages", MessageLive.Index, :index

      # NGO routes
      live "/ngo/profile", NGOLive.Profile, :edit
      live "/ngo/opportunities", NGOLive.Opportunities, :index
      live "/ngo/opportunities/new", NGOLive.Opportunities, :new
      live "/ngo/opportunities/:id/edit", NGOLive.Opportunities, :edit
      live "/ngo/applications", NGOLive.Applications, :index
      live "/ngo/volunteers", NGOLive.Volunteers, :index

      # Admin routes
      live "/admin/dashboard", AdminLive.Dashboard, :index
      live "/admin/users", AdminLive.Users, :index
      live "/admin/ngos", AdminLive.NGOs, :index
      live "/admin/opportunities", AdminLive.Opportunities, :index
      live "/admin/analytics", AdminLive.Analytics, :index
    end
  end

  scope "/", VolunteerMatchWeb do
    pipe_through [:browser]

    delete "/users/log_out", UserSessionController, :delete

    live_session :current_user,
      on_mount: [{VolunteerMatchWeb.UserAuth, :mount_current_user}] do
      live "/users/confirm/:token", UserConfirmationLive, :edit
      live "/users/confirm", UserConfirmationInstructionsLive, :new
    end
  end

  # API routes
  scope "/api", VolunteerMatchWeb.API, as: :api do
    pipe_through :api

    post "/auth/register", AuthController, :register
    post "/auth/login", AuthController, :login
    post "/auth/refresh", AuthController, :refresh
  end

  scope "/api", VolunteerMatchWeb.API, as: :api do
    pipe_through [:api, :api_authenticated]

    post "/auth/logout", AuthController, :logout

    resources "/opportunities", OpportunityController, except: [:new, :edit] do
      post "/apply", OpportunityController, :apply, as: :apply
      get "/nearby", OpportunityController, :nearby, as: :nearby
    end

    resources "/volunteers", VolunteerController, except: [:new, :edit, :delete]
    resources "/ngos", NGOController, except: [:new, :edit, :delete]
    resources "/applications", ApplicationController, only: [:index, :show, :update]
    resources "/messages", MessageController, except: [:new, :edit]
    resources "/reviews", ReviewController, except: [:new, :edit]

    get "/matches/volunteer/:volunteer_id", MatchController, :volunteer_matches
    get "/matches/opportunity/:opportunity_id", MatchController, :opportunity_matches
    post "/matches/:id/viewed", MatchController, :mark_viewed
    post "/matches/:id/dismissed", MatchController, :mark_dismissed

    get "/profile", ProfileController, :show
    put "/profile", ProfileController, :update
  end

  # Development routes
  if Application.compile_env(:volunteer_match, :dev_routes) do
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: VolunteerMatch.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end
end
