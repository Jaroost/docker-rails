# Load custom Keycloak OmniAuth strategy manually
# This file must be loaded before Devise/OmniAuth configuration
require Rails.root.join("lib/omniauth/strategies/keycloak")
