class SessionsController < ApplicationController
  # OAuth callback handler
  def create
    auth = request.env["omniauth.auth"]
    user = User.from_omniauth(auth)

    if user.persisted?
      session[:user_id] = user.id
      redirect_to root_path, notice: "Successfully signed in!"
    else
      redirect_to root_path, alert: "Failed to sign in. Please try again."
    end
  end

  # Signup - redirects to Keycloak registration page via OmniAuth
  def signup
    # Use OmniAuth authorization endpoint with kc_action=REGISTER parameter
    # This ensures proper CSRF protection via state parameter
    redirect_to "/auth/keycloak?kc_action=REGISTER", allow_other_host: false
  end

  # Logout handler
  def destroy
    session.delete(:user_id)
    @user = nil

    if params[:full_logout]
      # Full logout: also log out of Keycloak
      keycloak_logout_url = "#{ENV["KEYCLOAK_SITE"]}/realms/#{ENV["KEYCLOAK_REALM"]}/protocol/openid-connect/logout"
      redirect_url = CGI.escape(root_url)
      client_id = CGI.escape(ENV["KEYCLOAK_CLIENT_ID"])
      redirect_to "#{keycloak_logout_url}?client_id=#{client_id}&post_logout_redirect_uri=#{redirect_url}", allow_other_host: true, status: :see_other
    else
      # Session-only logout
      redirect_to root_path, notice: "Successfully signed out!", status: :see_other
    end
  end

  # OAuth failure handler
  def failure
    redirect_to root_path, alert: "Authentication failed: #{params[:message]}"
  end
end
