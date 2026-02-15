# frozen_string_literal: true

require "test_helper"

module Api
  module V1
    class UsersControllerTest < ActionDispatch::IntegrationTest
      # Mock JWT claims for testing
      def mock_jwt_claims(email: "test@example.com", username: "testuser", uid: "test-user-id-123")
        {
          "sub" => uid,
          "email" => email,
          "preferred_username" => username,
          "given_name" => "Test",
          "family_name" => "User",
          "exp" => 1.hour.from_now.to_i,
          "iat" => Time.current.to_i,
          "iss" => "#{ENV['KEYCLOAK_SITE']}/realms/#{ENV['KEYCLOAK_REALM']}"
        }
      end

      # Generate a fake JWT token for testing
      def generate_fake_token
        "fake.jwt.token.for.testing"
      end

      # Helper to mock KeycloakJwtValidator.validate
      def mock_jwt_validation(claims)
        KeycloakJwtValidator.define_singleton_method(:validate) do |_token|
          claims
        end
      end

      # Helper to mock KeycloakJwtValidator.validate to raise error
      def mock_jwt_validation_error(error)
        KeycloakJwtValidator.define_singleton_method(:validate) do |_token|
          raise error
        end
      end

      # Save original validate method before tests
      setup do
        @original_validate = KeycloakJwtValidator.method(:validate) if KeycloakJwtValidator.respond_to?(:validate)
      end

      # Cleanup after each test to restore original methods
      teardown do
        # Restore original validate method if it was saved
        if @original_validate
          KeycloakJwtValidator.define_singleton_method(:validate, @original_validate)
        elsif KeycloakJwtValidator.singleton_methods(false).include?(:validate)
          KeycloakJwtValidator.singleton_class.send(:remove_method, :validate)
        end
      end

      # Test: GET /api/v1/users/me without Authorization header
      test "should return 401 when Authorization header is missing" do
        get me_api_v1_users_url, as: :json

        assert_response :unauthorized
        assert_equal "Missing Authorization header", JSON.parse(response.body)["error"]
      end

      # Test: GET /api/v1/users/me with invalid token format
      test "should return 401 when token format is invalid" do
        # Mock JWT validation to raise decode error
        mock_jwt_validation_error(JWT::DecodeError.new("Not enough or too many segments"))

        get me_api_v1_users_url,
          headers: { "Authorization" => "Bearer invalid_token" },
          as: :json

        assert_response :unauthorized
        json_response = JSON.parse(response.body)
        assert json_response["error"].start_with?("Invalid or expired token")
      end

      # Test: GET /api/v1/users/me with valid JWT token
      test "should return current user when JWT token is valid" do
        # Mock the KeycloakJwtValidator to return claims without calling Keycloak
        claims = mock_jwt_claims(email: "api-user@example.com", username: "apiuser")
        mock_jwt_validation(claims)

        # Make request with fake token
        get me_api_v1_users_url,
          headers: { "Authorization" => "Bearer #{generate_fake_token}" },
          as: :json

        assert_response :success

        # Parse response
        json_response = JSON.parse(response.body)

        # Verify user data from JWT claims
        assert_equal "api-user@example.com", json_response["email"]
        assert_equal "apiuser", json_response["username"]
        assert_equal "Test", json_response["first_name"]
        assert_equal "User", json_response["last_name"]
        assert_equal "keycloak", json_response["provider"]
      end

      # Test: User auto-creation from JWT claims
      test "should create new user from JWT claims if user does not exist" do
        claims = mock_jwt_claims(
          email: "newuser@example.com",
          username: "brandnewuser",
          uid: "new-user-uid-456"
        )
        mock_jwt_validation(claims)

        # Verify user does not exist yet
        assert_nil User.find_by(email: "newuser@example.com")

        # Make API request
        get me_api_v1_users_url,
          headers: { "Authorization" => "Bearer #{generate_fake_token}" },
          as: :json

        assert_response :success

        # Verify user was created
        user = User.find_by(email: "newuser@example.com")
        assert_not_nil user
        assert_equal "brandnewuser", user.username
        assert_equal "Test", user.first_name
        assert_equal "User", user.last_name
        assert_equal "keycloak", user.provider
        assert_equal "new-user-uid-456", user.uid
      end

      # Test: User update from JWT claims on subsequent requests
      test "should update existing user from JWT claims" do
        # Create initial user with specific UID
        user = User.create!(
          provider: "keycloak",
          uid: "update-user-uid-789",
          email: "old-email@example.com",
          username: "oldusername",
          first_name: "Old",
          last_name: "Name"
        )

        # Mock JWT with updated information but same UID
        claims = mock_jwt_claims(
          email: "update-test@example.com",
          username: "updateuser",
          uid: "update-user-uid-789" # Same UID
        )
        mock_jwt_validation(claims)

        # Make API request
        get me_api_v1_users_url,
          headers: { "Authorization" => "Bearer #{generate_fake_token}" },
          as: :json

        assert_response :success

        # Verify user was updated
        user.reload
        assert_equal "update-test@example.com", user.email
        assert_equal "updateuser", user.username
        assert_equal "Test", user.first_name
        assert_equal "User", user.last_name
      end

      # Test: Trackable fields are updated on each API call
      test "should update trackable fields on each API call" do
        # Create user
        user = User.create!(
          provider: "keycloak",
          uid: "trackable-uid-101",
          email: "trackable@example.com",
          username: "trackuser",
          first_name: "Track",
          last_name: "User",
          sign_in_count: 0,
          current_sign_in_at: nil,
          last_sign_in_at: nil
        )

        old_updated_at = user.updated_at

        # Mock JWT claims
        claims = mock_jwt_claims(
          email: "trackable@example.com",
          username: "trackuser",
          uid: "trackable-uid-101"
        )
        mock_jwt_validation(claims)

        # Wait a bit to ensure timestamp difference
        sleep 0.1

        get me_api_v1_users_url,
          headers: { "Authorization" => "Bearer #{generate_fake_token}" },
          as: :json

        assert_response :success

        # Verify trackable fields were updated
        user.reload
        assert user.updated_at > old_updated_at
        assert_not_nil user.current_sign_in_at
      end

      # Test: JWT validation failure is handled gracefully
      test "should return 401 when JWT validation raises error" do
        # Mock validation to raise JWT::DecodeError
        mock_jwt_validation_error(JWT::DecodeError.new("Token expired"))

        get me_api_v1_users_url,
          headers: { "Authorization" => "Bearer #{generate_fake_token}" },
          as: :json

        assert_response :unauthorized
        json_response = JSON.parse(response.body)
        assert_equal "Invalid or expired token: Token expired", json_response["error"]
      end

      # Test: Missing required JWT claims
      test "should handle missing required JWT claims" do
        # Mock claims without email (required field)
        incomplete_claims = {
          "sub" => "test-user-id-123",
          "preferred_username" => "testuser",
          "given_name" => "Test",
          "family_name" => "User"
          # Missing "email"
        }
        mock_jwt_validation(incomplete_claims)

        get me_api_v1_users_url,
          headers: { "Authorization" => "Bearer #{generate_fake_token}" },
          as: :json

        # Should return 401 because User.from_jwt_claims will raise ArgumentError
        assert_response :unauthorized
        json_response = JSON.parse(response.body)
        assert_equal "Authentication failed", json_response["error"]
      end
    end
  end
end
