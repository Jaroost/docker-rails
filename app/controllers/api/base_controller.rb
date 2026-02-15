# frozen_string_literal: true

module Api
  # Base controller for all API endpoints
  # - Disables CSRF protection (stateless JWT authentication)
  # - Requires authentication for all API endpoints
  # - Includes ApiAuthenticatable for JWT validation
  class BaseController < ApplicationController
    # Skip CSRF protection for API requests (stateless JWT authentication)
    skip_forgery_protection

    # Override Devise's authenticate_user! to return 401 instead of redirecting
    before_action :authenticate_api_user!

    # Always respond with JSON
    respond_to :json

    private

    def authenticate_api_user!
      # Check if Bearer token is present
      unless request.headers["Authorization"].present?
        render json: { error: "Missing Authorization header" }, status: :unauthorized
        return
      end

      # Authenticate via JWT (handled by ApiAuthenticatable concern)
      authenticate_from_token!
    end
  end
end
