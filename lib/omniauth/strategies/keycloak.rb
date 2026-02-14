require "omniauth-oauth2"

module OmniAuth
  module Strategies
    class Keycloak < OmniAuth::Strategies::OAuth2
      option :name, "keycloak"
      
      option :client_options, {
        site: ENV["KEYCLOAK_SITE"],
        authorize_url: "/realms/#{ENV["KEYCLOAK_REALM"]}/protocol/openid-connect/auth",
        token_url: "/realms/#{ENV["KEYCLOAK_REALM"]}/protocol/openid-connect/token",
        userinfo_url: "/realms/#{ENV["KEYCLOAK_REALM"]}/protocol/openid-connect/userinfo"
      }
      
      uid { raw_info["sub"] }
      
      info do
        {
          email: raw_info["email"],
          first_name: raw_info["given_name"],
          last_name: raw_info["family_name"],
          name: raw_info["name"],
          preferred_username: raw_info["preferred_username"]
        }
      end
      
      extra do
        { raw_info: raw_info }
      end
      
      def raw_info
        @raw_info ||= access_token.get(options[:client_options][:userinfo_url]).parsed
      end
      
      def authorize_params
        super.tap do |params|
          # Remove kc_action from params since we'll handle it via URL
          params.delete(:kc_action) if params[:kc_action]
        end
      end
      
      def request_phase
        # Check if this is a registration request
        if request.params["kc_action"] == "register"
          # Store that this is a registration in session
          session["omniauth.is_registration"] = true
          # Use the registrations endpoint instead of auth endpoint
          options.client_options.authorize_url = "/realms/#{ENV["KEYCLOAK_REALM"]}/protocol/openid-connect/registrations"
          Rails.logger.info "✅ Using registration endpoint"
        else
          # Use normal auth endpoint
          options.client_options.authorize_url = "/realms/#{ENV["KEYCLOAK_REALM"]}/protocol/openid-connect/auth"
          session["omniauth.is_registration"] = false
        end
        
        super
      end
      
      def callback_url
        full_host + callback_path
      end
    end
  end
end
