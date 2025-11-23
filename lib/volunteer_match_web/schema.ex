defmodule VolunteerMatchWeb.Schema do
  use Absinthe.Schema

  import_types(Absinthe.Type.Custom)
  import_types(VolunteerMatchWeb.Schema.AccountTypes)
  import_types(VolunteerMatchWeb.Schema.OpportunityTypes)
  import_types(VolunteerMatchWeb.Schema.MatchTypes)
  import_types(VolunteerMatchWeb.Schema.MessageTypes)

  alias VolunteerMatchWeb.Resolvers

  query do
    @desc "Get current user"
    field :me, :user do
      resolve(&Resolvers.Accounts.me/3)
    end

    @desc "Get all opportunities"
    field :opportunities, list_of(:opportunity) do
      arg(:filter, :opportunity_filter)
      arg(:limit, :integer, default_value: 20)
      arg(:offset, :integer, default_value: 0)
      resolve(&Resolvers.Opportunities.list_opportunities/3)
    end

    @desc "Get opportunity by ID"
    field :opportunity, :opportunity do
      arg(:id, non_null(:id))
      resolve(&Resolvers.Opportunities.get_opportunity/3)
    end

    @desc "Search opportunities near location"
    field :opportunities_nearby, list_of(:opportunity_with_distance) do
      arg(:latitude, non_null(:float))
      arg(:longitude, non_null(:float))
      arg(:radius_km, :integer, default_value: 25)
      arg(:filter, :opportunity_filter)
      resolve(&Resolvers.Opportunities.nearby/3)
    end

    @desc "Get matches for current volunteer"
    field :my_matches, list_of(:match) do
      arg(:status, :match_status)
      arg(:min_score, :float, default_value: 50.0)
      arg(:limit, :integer, default_value: 20)
      resolve(&Resolvers.Matches.my_matches/3)
    end

    @desc "Get NGOs"
    field :ngos, list_of(:ngo) do
      arg(:filter, :ngo_filter)
      arg(:limit, :integer, default_value: 20)
      resolve(&Resolvers.NGOs.list_ngos/3)
    end

    @desc "Get analytics dashboard data"
    field :analytics, :analytics_data do
      resolve(&Resolvers.Analytics.dashboard/3)
    end

    @desc "Get my notifications"
    field :notifications, list_of(:notification) do
      arg(:unread_only, :boolean, default_value: false)
      arg(:limit, :integer, default_value: 50)
      resolve(&Resolvers.Notifications.list/3)
    end

    @desc "Get leaderboard"
    field :leaderboard, list_of(:leaderboard_entry) do
      arg(:type, :leaderboard_type, default_value: :top_volunteers)
      arg(:limit, :integer, default_value: 10)
      resolve(&Resolvers.Gamification.leaderboard/3)
    end
  end

  mutation do
    @desc "Register a new user"
    field :register, :auth_payload do
      arg(:email, non_null(:string))
      arg(:password, non_null(:string))
      arg(:first_name, non_null(:string))
      arg(:last_name, non_null(:string))
      arg(:role, non_null(:user_role))
      arg(:profile, :profile_input)
      resolve(&Resolvers.Accounts.register/3)
    end

    @desc "Login"
    field :login, :auth_payload do
      arg(:email, non_null(:string))
      arg(:password, non_null(:string))
      resolve(&Resolvers.Accounts.login/3)
    end

    @desc "Create opportunity"
    field :create_opportunity, :opportunity do
      arg(:input, non_null(:opportunity_input))
      resolve(&Resolvers.Opportunities.create/3)
    end

    @desc "Apply to opportunity"
    field :apply_to_opportunity, :application do
      arg(:opportunity_id, non_null(:id))
      arg(:message, :string)
      arg(:availability_notes, :string)
      resolve(&Resolvers.Opportunities.apply/3)
    end

    @desc "Review application"
    field :review_application, :application do
      arg(:application_id, non_null(:id))
      arg(:status, non_null(:application_status))
      arg(:reviewer_notes, :string)
      resolve(&Resolvers.Opportunities.review_application/3)
    end

    @desc "Send message"
    field :send_message, :message do
      arg(:recipient_id, non_null(:id))
      arg(:body, non_null(:string))
      arg(:subject, :string)
      resolve(&Resolvers.Messages.send/3)
    end

    @desc "Create review"
    field :create_review, :review do
      arg(:input, non_null(:review_input))
      resolve(&Resolvers.Reviews.create/3)
    end

    @desc "Mark notification as read"
    field :mark_notification_read, :notification do
      arg(:notification_id, non_null(:id))
      resolve(&Resolvers.Notifications.mark_read/3)
    end

    @desc "Follow user"
    field :follow_user, :follower do
      arg(:user_id, non_null(:id))
      resolve(&Resolvers.Social.follow/3)
    end

    @desc "Unfollow user"
    field :unfollow_user, :boolean do
      arg(:user_id, non_null(:id))
      resolve(&Resolvers.Social.unfollow/3)
    end
  end

  subscription do
    @desc "Subscribe to new messages"
    field :message_received, :message do
      arg(:user_id, non_null(:id))

      config(fn args, %{context: %{current_user: user}} ->
        if args.user_id == user.id do
          {:ok, topic: "messages:#{user.id}"}
        else
          {:error, "Unauthorized"}
        end
      end)

      trigger(:send_message, topic: fn message ->
        ["messages:#{message.recipient_id}"]
      end)
    end

    @desc "Subscribe to notifications"
    field :notification_received, :notification do
      config(fn _args, %{context: %{current_user: user}} ->
        {:ok, topic: "notifications:#{user.id}"}
      end)

      trigger([:apply_to_opportunity, :review_application], topic: fn
        %{volunteer: volunteer} -> ["notifications:#{volunteer.user_id}"]
        %{ngo: ngo} -> ["notifications:#{ngo.user_id}"]
        _ -> []
      end)
    end

    @desc "Subscribe to new matches"
    field :match_created, :match do
      config(fn _args, %{context: %{current_user: user}} ->
        case VolunteerMatch.Volunteers.get_volunteer_by_user_id(user.id) do
          nil -> {:error, "Not a volunteer"}
          volunteer -> {:ok, topic: "matches:#{volunteer.id}"}
        end
      end)
    end
  end

  def context(ctx) do
    loader =
      Dataloader.new()
      |> Dataloader.add_source(VolunteerMatch, VolunteerMatch.DataLoader.data())

    Map.put(ctx, :loader, loader)
  end

  def plugins do
    [Absinthe.Middleware.Dataloader] ++ Absinthe.Plugin.defaults()
  end
end
