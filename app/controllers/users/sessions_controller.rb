# frozen_string_literal: true

class Users::SessionsController < Devise::SessionsController
  skip_before_action :require_no_authentication, only: [ :new ]

  # Signup - redirects to Keycloak registration page via OmniAuth
  def signup
    # Use OmniAuth authorization endpoint with kc_action=REGISTER parameter
    # This ensures proper CSRF protection via state parameter
    redirect_to "/auth/keycloak?kc_action=REGISTER", allow_other_host: false
  end

  # Custom logout handler to support both session-only and full Keycloak logout
  def destroy
    if params[:full_logout]
      # Full logout: also log out of Keycloak
      keycloak_logout_url = "#{ENV["KEYCLOAK_SITE"]}/realms/#{ENV["KEYCLOAK_REALM"]}/protocol/openid-connect/logout"
      redirect_url = CGI.escape(root_url)
      client_id = CGI.escape(ENV["KEYCLOAK_CLIENT_ID"])

      # Sign out from Devise first
      signed_out = (Devise.sign_out_all_scopes ? sign_out : sign_out(resource_name))
      set_flash_message! :notice, :signed_out if signed_out

      # Redirect to Keycloak logout with return URL
      redirect_to "#{keycloak_logout_url}?client_id=#{client_id}&post_logout_redirect_uri=#{redirect_url}",
        allow_other_host: true,
        status: :see_other
    else
      # Session-only logout (default Devise behavior)
      super
    end
  end
end
