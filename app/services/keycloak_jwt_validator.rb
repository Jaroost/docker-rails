# frozen_string_literal: true

require "jwt"
require "net/http"
require "json"

# Service to validate JWT tokens issued by Keycloak using JWKS
class KeycloakJwtValidator
  # Cache JWKS for 1 hour to avoid repeated requests
  JWKS_CACHE_DURATION = 1.hour

  class << self
    # Validate a JWT token and return decoded claims
    # @param token [String] JWT token to validate
    # @return [Hash] Decoded JWT claims
    # @raise [JWT::DecodeError] If token is invalid
    def validate(token)
      # Decode and verify the JWT using JWKS
      decoded_token = JWT.decode(
        token,
        nil, # Public key will be fetched via jwks_loader
        true, # Verify signature
        {
          algorithms: [ "RS256" ], # Keycloak uses RS256
          iss: issuer_url, # Verify issuer
          verify_iss: true,
          jwks: jwks_loader
        }
      )

      # Return the payload (first element of decoded array)
      decoded_token.first
    rescue JWT::DecodeError => e
      Rails.logger.error "JWT validation failed: #{e.message}"
      raise
    end

    private

    # Lazy-loading JWKS fetcher with caching
    # This lambda is called by JWT library when needed
    def jwks_loader
      @jwks_loader ||= lambda do |options|
        # Check if JWKS is cached and still valid
        if @cached_jwks.present? && @jwks_cache_expires_at.present? && Time.current < @jwks_cache_expires_at
          return @cached_jwks
        end

        # Fetch fresh JWKS from Keycloak
        Rails.logger.info "Fetching JWKS from Keycloak..."
        @cached_jwks = fetch_jwks
        @jwks_cache_expires_at = JWKS_CACHE_DURATION.from_now

        @cached_jwks
      end
    end

    # Fetch JWKS from Keycloak's JWKS endpoint
    def fetch_jwks
      uri = URI(jwks_url)
      response = Net::HTTP.get_response(uri)

      unless response.is_a?(Net::HTTPSuccess)
        raise "Failed to fetch JWKS: #{response.code} #{response.message}"
      end

      # Parse JWKS response and convert to JWT library format
      jwks_data = JSON.parse(response.body)
      { keys: jwks_data["keys"] }
    rescue StandardError => e
      Rails.logger.error "Error fetching JWKS: #{e.message}"
      raise
    end

    # Keycloak JWKS endpoint URL
    def jwks_url
      "#{ENV["KEYCLOAK_SITE"]}/realms/#{ENV["KEYCLOAK_REALM"]}/protocol/openid-connect/certs"
    end

    # Expected token issuer
    def issuer_url
      "#{ENV["KEYCLOAK_SITE"]}/realms/#{ENV["KEYCLOAK_REALM"]}"
    end
  end
end
