class User < ApplicationRecord
  # Include Devise modules for OAuth-only authentication
  # :omniauthable - Enable OmniAuth authentication
  # :trackable - Track sign-in count and timestamps
  # :rememberable - Support "remember me" functionality
  # Note: NOT using :database_authenticatable (OAuth-only, no password)
  devise :omniauthable, :trackable, :rememberable,
    omniauth_providers: [ :keycloak ]

  # Create or update user from OmniAuth authentication data
  def self.from_omniauth(auth)
    where(provider: auth.provider, uid: auth.uid).first_or_create do |user|
      user.email = auth.info.email
      user.username = auth.info.preferred_username || auth.info.email&.split("@")&.first
      user.first_name = auth.info.first_name || auth.info.given_name
      user.last_name = auth.info.last_name || auth.info.family_name
      user.token = auth.credentials.token
      user.refresh_token = auth.credentials.refresh_token
      user.token_expires_at = auth.credentials.expires_at ? Time.at(auth.credentials.expires_at) : nil
    end.tap do |user|
      # Update token and last sign-in time on each login
      user.update(
        token: auth.credentials.token,
        refresh_token: auth.credentials.refresh_token,
        token_expires_at: auth.credentials.expires_at ? Time.at(auth.credentials.expires_at) : nil,
        last_sign_in_at: Time.current
      )
    end
  end

  # Create or find user from JWT claims (for API authentication)
  def self.from_jwt_claims(jwt_claims)
    # Extract user information from JWT claims
    # Standard OIDC claims: sub (subject/user ID), email, preferred_username, given_name, family_name
    uid = jwt_claims["sub"]
    email = jwt_claims["email"]
    preferred_username = jwt_claims["preferred_username"]
    given_name = jwt_claims["given_name"]
    family_name = jwt_claims["family_name"]

    # Validate required claims
    raise ArgumentError, "Missing required JWT claims: sub and email" if uid.blank? || email.blank?

    # Find or create user by provider and uid (same as OAuth flow)
    where(provider: "keycloak", uid: uid).first_or_create do |user|
      user.email = email
      user.username = preferred_username || email.split("@").first
      user.first_name = given_name
      user.last_name = family_name
    end.tap do |user|
      # Update user info from JWT on each API call (in case it changed in Keycloak)
      user.update(
        email: email,
        username: preferred_username || email.split("@").first,
        first_name: given_name,
        last_name: family_name
      )
    end
  end
end
