require "test_helper"
require "ostruct"

class UserRolesTest < ActiveSupport::TestCase
  test "maps keycloak admin role to admin" do
    claims = { "realm_access" => { "roles" => ["Admin"] } }
    assert_equal :admin, User.map_keycloak_roles_to_app_role(User.extract_keycloak_roles(claims))
  end

  test "maps keycloak reader role to reader" do
    claims = { "realm_access" => { "roles" => ["Reader"] } }
    assert_equal :reader, User.map_keycloak_roles_to_app_role(User.extract_keycloak_roles(claims))
  end

  test "defaults to reader when no known keycloak role is present" do
    claims = { "realm_access" => { "roles" => ["UnknownRole"] } }
    assert_equal :reader, User.map_keycloak_roles_to_app_role(User.extract_keycloak_roles(claims))
  end

  test "extracts roles from all resource_access clients" do
    claims = {
      "resource_access" => {
        "account" => { "roles" => ["manage-account"] },
        "my-client" => { "roles" => ["Admin"] }
      }
    }

    assert_includes User.extract_keycloak_roles(claims), "Admin"
  end

  test "from_omniauth maps role from access token claims" do
    auth = OpenStruct.new(
      provider: "keycloak",
      uid: "kc-123",
      info: OpenStruct.new(
        email: "role-from-token@example.com",
        preferred_username: "role-from-token",
        first_name: "Role",
        last_name: "Token"
      ),
      credentials: OpenStruct.new(
        token: unsigned_jwt("realm_access" => { "roles" => ["Admin"] }),
        refresh_token: "refresh-token",
        expires_at: 1.hour.from_now.to_i
      ),
      extra: OpenStruct.new(raw_info: { "sub" => "kc-123", "email" => "role-from-token@example.com" })
    )

    user = User.from_omniauth(auth)

    assert_equal "admin", user.role
  end

  private

  def unsigned_jwt(payload)
    JWT.encode(payload, nil, "none")
  end
end
