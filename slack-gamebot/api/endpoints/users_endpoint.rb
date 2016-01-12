module Api
  module Endpoints
    class UsersEndpoint < Grape::API
      format :json
      helpers Api::Helpers::CursorHelpers
      helpers Api::Helpers::SortHelpers
      helpers Api::Helpers::PaginationParameters

      namespace :users do
        desc 'Get a user.'
        params do
          requires :id, type: String, desc: 'User ID.'
        end
        get ':id' do
          user = User.find(params[:id]) || error!('Not Found', 404)
          error!('Not Found', 404) unless user.team.api?
          present user, with: Api::Presenters::UserPresenter
        end

        desc 'Get all the users.'
        params do
          requires :team_id, type: String
          optional :captain, type: Boolean
          use :pagination
        end
        sort User::SORT_ORDERS
        get do
          team = Team.find(params[:team_id]) || error!('Not Found', 404)
          error!('Not Found', 404) unless team.api?
          query = team.users
          query = query.captains if params[:captain]
          users = paginate_and_sort_by_cursor(query, default_sort_order: '-elo')
          present users, with: Api::Presenters::UsersPresenter
        end
      end
    end
  end
end
