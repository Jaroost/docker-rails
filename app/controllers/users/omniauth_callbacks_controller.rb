# frozen_string_literal: true

class Users::OmniauthCallbacksController < Devise::OmniauthCallbacksController
  # Keycloak OAuth callback handler
  # This method is called after successful authentication with Keycloak
  def keycloak
    auth = request.env["omniauth.auth"]
    @user = User.from_omniauth(auth)

    if @user.persisted?
      # Sign in the user with Devise
      sign_in_and_redirect @user, event: :authentication
      set_flash_message(:notice, :success, kind: "Keycloak") if is_navigational_format?
    else
      # Handle failure - redirect to new user registration (should not happen with OAuth)
      session["devise.keycloak_data"] = request.env["omniauth.auth"].except(:extra)
      redirect_to new_user_registration_url, alert: @user.errors.full_messages.join("\n")
    end
  end

  # OmniAuth failure handler
  # Called when OAuth authentication fails
  def failure
    redirect_to root_path, alert: "Authentication failed: #{failure_message}"
  end

  protected

  def failure_message
    exception = request.env["omniauth.error"]
    error   = exception.error_reason if exception.respond_to?(:error_reason)
    error ||= exception.error        if exception.respond_to?(:error)
    error ||= (request.params["message"] || exception.message) if exception.respond_to?(:message)
    error.to_s.humanize if error
  end
end
