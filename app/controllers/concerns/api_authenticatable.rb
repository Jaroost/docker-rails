# frozen_string_literal: true

# Concern to enable JWT-based API authentication alongside session-based authentication
# Detects Bearer tokens in Authorization header and validates them using Keycloak JWKS
module ApiAuthenticatable
  extend ActiveSupport::Concern

  included do
    before_action :authenticate_from_token!, if: :api_request?
  end

  private

  # Check if this is an API request (has Authorization: Bearer header)
  def api_request?
    request.headers["Authorization"].present? && request.headers["Authorization"].start_with?("Bearer ")
  end

  # Authenticate user from JWT token
  def authenticate_from_token!
    token = extract_token_from_header

    begin
      # Validate JWT and get claims
      jwt_claims = KeycloakJwtValidator.validate(token)

      # Find or create user from JWT claims
      @current_user = User.from_jwt_claims(jwt_claims)

      # Track sign-in for Devise trackable
      if @current_user && @current_user.persisted?
        @current_user.update_tracked_fields!(request)
      end
    rescue JWT::DecodeError => e
      render_unauthorized("Invalid or expired token: #{e.message}")
    rescue StandardError => e
      Rails.logger.error "API authentication error: #{e.message}"
      render_unauthorized("Authentication failed")
    end
  end

  # Override Devise's current_user to use @current_user from JWT
  def current_user
    @current_user || super
  end

  # Override Devise's user_signed_in? to check JWT auth as well
  def user_signed_in?
    current_user.present?
  end

  # Extract Bearer token from Authorization header
  def extract_token_from_header
    request.headers["Authorization"].split(" ").last
  end

  # Render 401 Unauthorized response
  def render_unauthorized(message)
    render json: { error: message }, status: :unauthorized
  end
end
