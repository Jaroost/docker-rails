require "test_helper"

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
end
