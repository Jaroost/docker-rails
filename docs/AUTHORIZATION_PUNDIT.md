# Authorization with Pundit

## Current setup
- Authorization gem: `pundit`
- Local app roles on `User`:
  - `reader`: read-only access to `ArticlesRequest`
  - `admin`: full CRUD access to `ArticlesRequest`
- Keycloak roles mapped automatically to app roles:
  - `Admin` -> `admin`
  - `Reader` -> `reader`
  - unknown role -> `reader` (safe default)

## Where it is implemented
- Pundit integration: `app/controllers/application_controller.rb`
- Base policy: `app/policies/application_policy.rb`
- ArticlesRequest permissions: `app/policies/articles_request_policy.rb`
- Keycloak role mapping: `app/models/user.rb`
- Controller enforcement: `app/controllers/articles_requests_controller.rb`

## How to add a new role
1. Update `User` enum in `app/models/user.rb`.
2. Add migration if enum storage changes are needed.
3. Update mapping method:
- `User.map_keycloak_roles_to_app_role`
4. Update policies to use the new role.
5. Add/adjust tests.

Example (`manager` role):
```ruby
# app/models/user.rb
enum :role, { reader: 0, manager: 1, admin: 2 }, default: :reader

def self.map_keycloak_roles_to_app_role(keycloak_roles)
  normalized = keycloak_roles.map(&:downcase)
  return :admin if normalized.include?("admin")
  return :manager if normalized.include?("manager")
  return :reader if normalized.include?("reader")
  :reader
end
```

## How to add permissions on a resource
1. Create a policy file `app/policies/<resource>_policy.rb`.
2. Define action methods (`index?`, `show?`, `create?`, `update?`, `destroy?`).
3. Define `Scope#resolve` for query filtering.
4. In controller:
- `policy_scope(Model)` for index
- `authorize record_or_class` for each action
5. In views, conditionally show actions:
- `policy(record).edit?`
- `policy(Model).new?`

Example:
```ruby
class InvoicePolicy < ApplicationPolicy
  def index?
    user.admin? || user.reader?
  end

  def create?
    user.admin?
  end

  class Scope < Scope
    def resolve
      user.admin? ? scope.all : scope.where(public: true)
    end
  end
end
```

## Keycloak role expectations
- Roles must be present in token claims:
  - `realm_access.roles`
  - optionally `resource_access.<KEYCLOAK_CLIENT_ID>.roles`
- Role names are case-insensitive in mapping logic.

## Testing guidance
- Controller tests:
  - sign in as each role
  - verify allowed/denied actions
- Policy tests:
  - explicit assertions on each action
- API tests:
  - verify role mapping from JWT claims
