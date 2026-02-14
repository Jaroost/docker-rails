require "omniauth"
require Rails.root.join("lib", "omniauth", "strategies", "keycloak")

Rails.application.config.middleware.use OmniAuth::Builder do
  provider :keycloak,
    ENV["KEYCLOAK_CLIENT_ID"],
    ENV["KEYCLOAK_CLIENT_SECRET"],
    scope: "openid email profile"
end

# Enable CSRF protection for OmniAuth
OmniAuth.config.allowed_request_methods = [ :post ]
