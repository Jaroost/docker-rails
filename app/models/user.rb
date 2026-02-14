class User < ApplicationRecord
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
end
