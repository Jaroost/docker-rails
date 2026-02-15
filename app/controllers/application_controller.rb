class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Enable JWT-based API authentication alongside session-based authentication
  include ApiAuthenticatable

  # Devise provides the following helper methods:
  # - current_user: Returns the currently signed-in user (overridden by ApiAuthenticatable for JWT)
  # - user_signed_in?: Returns true if a user is signed in (overridden by ApiAuthenticatable for JWT)
  # - authenticate_user!: Redirects to sign-in page if user is not authenticated
end
