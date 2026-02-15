# frozen_string_literal: true

require "test_helper"

class KeycloakJwtValidatorTest < ActiveSupport::TestCase
  setup do
    # Clear any cached JWKS before each test
    KeycloakJwtValidator.instance_variable_set(:@cached_jwks, nil)
    KeycloakJwtValidator.instance_variable_set(:@jwks_cache_expires_at, nil)
  end

  test "issuer_url returns correct Keycloak issuer URL" do
    expected = "#{ENV['KEYCLOAK_SITE']}/realms/#{ENV['KEYCLOAK_REALM']}"
    assert_equal expected, KeycloakJwtValidator.send(:issuer_url)
  end

  test "jwks_url returns correct Keycloak JWKS endpoint" do
    expected = "#{ENV['KEYCLOAK_SITE']}/realms/#{ENV['KEYCLOAK_REALM']}/protocol/openid-connect/certs"
    assert_equal expected, KeycloakJwtValidator.send(:jwks_url)
  end

  test "validate raises JWT::DecodeError for invalid token format" do
    invalid_token = "invalid.jwt.token"

    assert_raises JWT::DecodeError do
      KeycloakJwtValidator.validate(invalid_token)
    end
  end

  test "validate raises error for token with insufficient segments" do
    short_token = "invalid"

    assert_raises JWT::DecodeError do
      KeycloakJwtValidator.validate(short_token)
    end
  end

  test "JWKS_CACHE_DURATION constant is set to 1 hour" do
    assert_equal 1.hour, KeycloakJwtValidator::JWKS_CACHE_DURATION
  end

  test "jwks_loader returns a lambda" do
    loader = KeycloakJwtValidator.send(:jwks_loader)
    assert_instance_of Proc, loader
  end

  test "jwks_loader caches JWKS between calls" do
    mock_jwks = {
      keys: [
        {
          kid: "test-key-id",
          kty: "RSA",
          use: "sig",
          n: "test-n",
          e: "AQAB"
        }
      ]
    }

    # Mock fetch_jwks to track calls
    original_fetch = KeycloakJwtValidator.method(:fetch_jwks)
    call_count = 0

    KeycloakJwtValidator.define_singleton_method(:fetch_jwks) do
      call_count += 1
      mock_jwks
    end

    begin
      loader = KeycloakJwtValidator.send(:jwks_loader)

      # First call should fetch
      result1 = loader.call({})
      assert_equal 1, call_count
      assert_equal mock_jwks, result1

      # Second call should use cache (same object)
      result2 = loader.call({})
      assert_equal 1, call_count, "JWKS should be cached"
      assert_equal mock_jwks, result2

      # Verify cache variables are set
      assert_not_nil KeycloakJwtValidator.instance_variable_get(:@cached_jwks)
      assert_not_nil KeycloakJwtValidator.instance_variable_get(:@jwks_cache_expires_at)
    ensure
      # Restore original method
      KeycloakJwtValidator.define_singleton_method(:fetch_jwks, original_fetch)
    end
  end

  test "jwks_loader refetches JWKS after cache expires" do
    mock_jwks = {
      keys: [
        {
          kid: "test-key-id",
          kty: "RSA",
          use: "sig",
          n: "test-n",
          e: "AQAB"
        }
      ]
    }

    # Mock fetch_jwks
    original_fetch = KeycloakJwtValidator.method(:fetch_jwks)
    call_count = 0

    KeycloakJwtValidator.define_singleton_method(:fetch_jwks) do
      call_count += 1
      mock_jwks
    end

    begin
      loader = KeycloakJwtValidator.send(:jwks_loader)

      # First call
      loader.call({})
      assert_equal 1, call_count

      # Manually expire the cache
      KeycloakJwtValidator.instance_variable_set(
        :@jwks_cache_expires_at,
        1.second.ago
      )

      # Next call should fetch again
      loader.call({})
      assert_equal 2, call_count, "JWKS should be fetched again after expiry"
    ensure
      # Restore original method
      KeycloakJwtValidator.define_singleton_method(:fetch_jwks, original_fetch)
    end
  end
end
