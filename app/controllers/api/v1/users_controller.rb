# frozen_string_literal: true

module Api
  module V1
    # API endpoint for user information
    class UsersController < Api::BaseController
      # GET /api/v1/users/me
      # Returns current user information from JWT token
      def me
        render json: {
          id: current_user.id,
          email: current_user.email,
          username: current_user.username,
          first_name: current_user.first_name,
          last_name: current_user.last_name,
          provider: current_user.provider,
          created_at: current_user.created_at,
          updated_at: current_user.updated_at
        }
      end
    end
  end
end
