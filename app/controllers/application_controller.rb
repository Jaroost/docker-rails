class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  include Pundit::Authorization

  # Enable JWT-based API authentication alongside session-based authentication
  include ApiAuthenticatable

  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized

  # Devise provides the following helper methods:
  # - current_user: Returns the currently signed-in user (overridden by ApiAuthenticatable for JWT)
  # - user_signed_in?: Returns true if a user is signed in (overridden by ApiAuthenticatable for JWT)
  # - authenticate_user!: Redirects to sign-in page if user is not authenticated

  private

  def user_not_authorized
    respond_to do |format|
      format.html { redirect_to root_path, alert: "Vous n'êtes pas autorisé à effectuer cette action." }
      format.json { render json: { error: "Forbidden" }, status: :forbidden }
      format.any { head :forbidden }
    end
  end
end
