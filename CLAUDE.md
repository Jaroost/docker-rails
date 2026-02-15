# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**rails-base** is a modern Rails 8.1 application with a Vue 3 + Bootstrap frontend, using Vite for asset bundling. It uses PostgreSQL for the database and includes solid-cache, solid-queue, and solid-cable for built-in database-backed infrastructure.

**Tech Stack:**
- Backend: Rails 8.1, Ruby 3.3.10, PostgreSQL 16
- Frontend: Vue 3, Bootstrap 5, Vite, TypeScript
- Authentication: Devise + Keycloak (OAuth 2.0/OIDC)
- API: JWT stateless authentication (Keycloak JWKS validation)
- Asset Pipeline: Propshaft + Vite Ruby
- Job Queue: Solid Queue (database-backed)
- Real-time: Solid Cable (database-backed)
- Caching: Solid Cache (database-backed)
- Deployment: Docker, Kamal

### Authentication

**Web (Browser):**
- Devise + Keycloak OAuth 2.0 (OpenID Connect)
- Session-based authentication (cookies)
- Custom OmniAuth strategy for Keycloak 17+ compatibility
- Two logout modes: session-only and full Keycloak logout
- Direct signup flow via Keycloak registration endpoint

**API (Stateless):**
- JWT Bearer token authentication
- Tokens validated using Keycloak JWKS (RS256 signatures)
- JWKS cache (1 hour) for performance
- Auto-create/update users from JWT claims
- No sessions or CSRF protection (stateless)

**User Model:**
- Stores OAuth tokens and user profile
- Single model for both web and API authentication
- Devise modules: `:omniauthable`, `:trackable`, `:rememberable`

## Development Setup

### Prerequisites
- Ruby 3.3.10 (see `.ruby-version`)
- PostgreSQL 16
- Redis 7
- Node.js 20 + pnpm

### Local Development (with Docker) - Recommended
```bash
# Set up environment (required - must have POSTGRES_PASSWORD)
echo "POSTGRES_PASSWORD=yourpassword" > .env

# Start all services (PostgreSQL, Redis, Rails, Vite)
docker compose up -d

# First time: run migrations
docker compose exec web bin/rails db:prepare

# View logs
docker compose logs -f web    # Rails logs
docker compose logs -f vite   # Vite dev logs

# Run commands inside containers
docker compose exec web bin/rails console
docker compose exec web bin/rails test
docker compose exec web pnpm run vue-tsc --noEmit
```

**Access the app:**
- **Rails app**: `https://rails.localtest.me` (via Traefik)
- **Portainer**: `https://portainer.localtest.me` (container management)
- **Traefik Dashboard**: `https://traefik.localtest.me`

**Requirements:**
- Traefik must be running on the `proxy` network (shared across all Docker projects)
- Environment variable `POSTGRES_PASSWORD` must be set in `.env`

**How it works:**
1. Two Docker services: `web` (Rails on port 3000) and `vite` (Vite dev on port 3036)
2. Rails detects Vite via Docker DNS (`http://vite:3036`) for HMR detection
3. Vite assets are proxied by Rails/Propshaft from `/vite/*` to Vite server
4. HMR (WebSocket) connects to `ws://localhost:3036` (accessible from browser)
5. Changes to Vue/JS files hot-reload automatically in browser
6. Traefik routes HTTPS traffic to Rails container

### Local Development (without Docker)
```bash
# Install dependencies
bundle install
pnpm install

# Setup database
bin/rails db:prepare

# Run the development server and Vite
bin/rails server      # Port 3000
bin/vite dev          # Port 3036 (auto HMR)
```

## Common Commands

### Running Tests
```bash
# Run all tests
bin/rails test

# Run a specific test file
bin/rails test test/controllers/home_controller_test.rb

# Run a specific test method
bin/rails test test/controllers/home_controller_test.rb:10

# Run tests in parallel (configured in test_helper.rb)
bin/rails test --parallel
```

### Linting & Code Quality
```bash
# Run RuboCop (Omakase style)
bundle exec rubocop

# Security audit for Gems
bundle exec bundler-audit

# Security scan for Rails vulnerabilities
bundle exec brakeman
```

### Database
```bash
# Create/reset test database
bin/rails db:prepare

# Run migrations
bin/rails db:migrate

# Create a new migration
bin/rails generate migration MigrationName

# Check database status
bin/rails db:version
```

### Asset Building
```bash
# Build assets for production
bin/vite build

# Check TypeScript for errors
pnpm run vue-tsc --noEmit
```

### Authentication & Keycloak
```bash
# Check Keycloak status
docker compose ps keycloak
docker compose logs -f keycloak

# Access Keycloak admin console
# URL: https://keycloak.localtest.me
# Username: admin / Password: admin

# Test API with JWT token (see API.md for complete examples)
TOKEN=$(curl -s -X POST "https://keycloak.localtest.me/realms/rails-base/protocol/openid-connect/token" \
  -d "grant_type=client_credentials" \
  -d "client_id=YOUR_CLIENT_ID" \
  -d "client_secret=YOUR_CLIENT_SECRET" | jq -r '.access_token')

curl -X GET "https://rails.localtest.me/api/v1/users/me" \
  -H "Authorization: Bearer $TOKEN"

# Verify users in database
docker compose exec web bin/rails runner "puts User.all.to_json"

# Force recreate web service after .env changes
docker compose up -d --force-recreate web
```

### General
```bash
# Open Rails console
bin/rails console

# Generate scaffolding
bin/rails generate scaffold Post title:string body:text

# Run arbitrary Rake tasks
bin/rails -T  # List all available tasks
```

## Architecture

### Frontend (Vue 3 + Vite)
- **Entrypoint:** `app/javascript/entrypoints/application.ts`
  - Imports Bootstrap CSS
  - Mounts Vue App to `#vue-app` element
- **Components:** `app/javascript/components/`
  - `App.vue` is the root Vue component
- **TypeScript:** `tsconfig.json` configured; run `pnpm run vue-tsc` to check types
- **Vite Config:** `vite.config.ts`
  - Uses `vite-plugin-ruby` for Rails integration
  - Configured to listen on `0.0.0.0:3036` HTTP
- **Vite Config (development):** `config/vite.json`
  - `port: 3036`, `host: 0.0.0.0`, `https: false`

### Backend (Rails)
- **Controllers:** `app/controllers/`
  - `application_controller.rb` - Base controller with authentication helpers
  - `users/sessions_controller.rb` - OAuth login/logout with Keycloak
  - `users/omniauth_callbacks_controller.rb` - OAuth callback handler
  - `api/base_controller.rb` - Base controller for JWT API (stateless)
  - `api/v1/users_controller.rb` - API user endpoints
- **Models:** `app/models/`
  - `user.rb` - Devise model with OAuth and JWT support
- **Services:** `app/services/`
  - `keycloak_jwt_validator.rb` - JWT validation with Keycloak JWKS
- **Concerns:** `app/controllers/concerns/`
  - `api_authenticatable.rb` - JWT authentication concern
- **Custom OmniAuth:** `lib/omniauth/strategies/keycloak.rb`
  - Custom strategy for Keycloak 17+ compatibility
  - Handles both login and signup flows (switches endpoints dynamically)
- **Views:** `app/views/` (mostly view templates; UI handled via Vue)
- **Routes:** `config/routes.rb` (Devise + custom session routes + API namespace)
- **Helpers:** `app/helpers/`
- **Jobs:** `app/jobs/` (uses Solid Queue)
- **Mailers:** `app/mailers/`

### Database
- **Config:** `config/database.yml`
- **Primary database:** `app_development` (development), `app_test` (test)
- **Solid infrastructure:** Multiple database connections for cache/queue/cable
- **Migrations:** `db/migrate/`, `db/cache_migrate/`, `db/queue_migrate/`, `db/cable_migrate/`

### API (JWT Authentication)
- **Base Controller:** `app/controllers/api/base_controller.rb`
  - Skips CSRF protection (stateless)
  - Requires JWT Bearer token in Authorization header
  - Always responds with JSON
- **Concern:** `app/controllers/concerns/api_authenticatable.rb`
  - Extracts and validates JWT from Authorization header
  - Uses `KeycloakJwtValidator` service for token validation
  - Auto-creates/updates users from JWT claims
  - Overrides Devise's `current_user` for API context
- **Service:** `app/services/keycloak_jwt_validator.rb`
  - Validates JWT signatures using Keycloak JWKS endpoint
  - Caches JWKS keys (1 hour) for performance
  - Verifies issuer, expiration, and algorithm (RS256 only)
- **Endpoints:** `app/controllers/api/v1/`
  - `GET /api/v1/users/me` - Returns current user profile from JWT token
- **Documentation:** See `API.md` for complete usage examples

### Configuration
- **Environment:** `config/environment.rb` + `config/environments/{development,test,production}.rb`
- **Application settings:** `config/application.rb`
  - Modern browser only (webp, web-push, CSS nesting support required)
  - Configured hosts: localhost, rails.localtest.me
- **Credentials:** `config/credentials.yml.enc` + `config/master.key` (encrypted secrets)
- **Devise:** `config/initializers/devise.rb` - Devise configuration
- **SSL (dev only):** `config/initializers/00_openssl_dev.rb` - Disables SSL verification (NEVER in production!)

### Docker
- **Dockerfile:** Multi-service build (Ruby 3.3-slim + Node 20 + pnpm)
- **docker-compose.yml:** Orchestrates web, vite, db, redis, keycloak, pgadmin
  - `web` service: Rails on port 3000, detects Vite via `VITE_RUBY_HOST=vite` + `VITE_RUBY_PORT=3036`
  - `vite` service: Vite dev server on port 3036 (HTTP)
  - `keycloak` service: Identity server accessible at https://keycloak.localtest.me
  - `db` service: PostgreSQL with separate databases (app, keycloak, cache, queue, cable)
  - Traefik labels for HTTPS routing (rails.localtest.me, keycloak.localtest.me, pgadmin.localtest.me)
  - External network "proxy" required (for Traefik reverse proxy)
  - `extra_hosts` in web service: allows Rails to resolve keycloak.localtest.me via Traefik
  - `node_modules` stored in anonymous volume for vite service (not bind-mounted)
- **Entrypoints:**
  - `bin/docker-entrypoint` (web service): runs bundle install, pnpm install, db:prepare
  - `bin/vite-dev-entrypoint` (vite service): runs pnpm install with CI mode and fixes esbuild permissions

### Testing
- **Test Helper:** `test/test_helper.rb`
  - Tests run in parallel by default
  - All fixtures auto-loaded
- **Test Directories:**
  - `test/controllers/` - Controller tests
  - `test/models/` - Model tests
  - `test/integration/` - Integration tests
  - `test/mailers/` - Mailer tests
  - `test/helpers/` - Helper tests
  - `test/fixtures/` - Test data

## Key Files Reference
- `.env` - Environment variables (POSTGRES_PASSWORD, Keycloak OAuth config)
- `Gemfile` / `Gemfile.lock` - Ruby dependencies
- `package.json` / `pnpm-lock.yaml` - JavaScript dependencies
- `.ruby-version` - Ruby version (3.3.10)
- `Dockerfile` - Container image definition
- `docker-compose.yml` - Multi-container setup with Traefik + Keycloak
- `vite.config.ts` - Frontend bundler configuration (HMR setup)
- `tsconfig.json` - TypeScript configuration
- `HMR_SETUP.md` - Guide for multi-application Vite HMR setup with Traefik
- `KEYCLOAK_SETUP.md` - Complete Keycloak OAuth setup guide (realm, client, users)
- `API.md` - API documentation with JWT authentication examples

## Vite + HMR Configuration Details

The Vite setup with Docker requires correct configuration in these files:

**vite.config.ts:**
```typescript
base: "/",  // Asset base path
server: {
  host: "0.0.0.0",           // Listen on all interfaces
  port: 3036,                 // Dev server port
  https: false,               // Plain HTTP (TLS handled by Traefik frontend)
  allowedHosts: ["vite", "localhost", "127.0.0.1"],  // Accept requests from Rails
  hmr: {
    host: "localhost",        // Browser connects to localhost
    port: 3036,               // Direct to Vite dev server port
    protocol: "ws",           // Plain WebSocket (no TLS)
  },
}
```

**config/vite.json (development):**
```json
{
  "development": {
    "autoBuild": true,
    "port": 3036,
    "host": "0.0.0.0",
    "https": false
  }
}
```
Note: No `publicOutputDir` - let vite-plugin-ruby auto-detect `/vite/` prefix

**docker-compose.yml:**
- `VITE_RUBY_HOST: "vite"` - Rails finds Vite via Docker DNS for HMR detection
- `VITE_RUBY_PORT: "3036"` - Rails detection port
- Traefik labels: simple HTTPS routing for Rails to port 3000 only
- Both `web` and `vite` services on `proxy` network for Docker DNS

**How the data flows:**
1. Browser → Traefik HTTPS → Rails (port 3000) on `rails.localtest.me`
2. Rails renders HTML with `/vite/@vite/client` and `/vite/entrypoints/application.ts` script tags
3. Browser → Rails (internal proxy) → Vite (port 3036) for assets (`/vite/*`)
4. Browser → WebSocket `ws://localhost:3036` for HMR (direct connection, no proxy needed)

## Common Issues & Solutions

**Assets not loading (404 on `/vite/*`):**
- Ensure Vite is running: `docker compose logs vite | grep ready`
- Check Vite listens on `/vite/`: `docker compose logs vite | grep "➜"`
- Verify Rails can reach Vite: `docker compose exec web curl http://vite:3036/vite/@vite/client`

**HMR WebSocket connection failing:**
- Browser console should show: `[vite] connected` (not `failed to connect`)
- Ensure `server.hmr` in `vite.config.ts` is set to `localhost:3036` with `ws://` protocol
- WebSocket should connect to `ws://localhost:3036` (port 3036, not 443)

**Vite adding `/vite/` prefix unexpectedly:**
- Don't set `publicOutputDir` in `config/vite.json` - let vite-plugin-ruby auto-detect
- Set `base: "/"` in `vite.config.ts` if needed to override

**Vite failing to start with esbuild EACCES error:**
- **Problem:** pnpm v10+ ignores build scripts by default for security, causing esbuild binaries to lack execute permissions
- **Solution:** The `bin/vite-dev-entrypoint` script handles this automatically:
  - Uses `CI=true pnpm install` to avoid interactive prompts
  - Fixes esbuild binary permissions with `chmod +x` after install
- **Manual fix if needed:**
  ```bash
  docker compose exec vite chmod -R +x node_modules/.pnpm/@esbuild*/node_modules/@esbuild/*/bin/*
  ```
- **Note:** The `vite` service uses a separate entrypoint (`bin/vite-dev-entrypoint`) that only installs node dependencies without Rails/database setup

## Notes

- **Authentication:** Devise with Keycloak OAuth for web sessions, JWT for API requests. See `KEYCLOAK_SETUP.md` for OAuth configuration and `API.md` for JWT usage.
- **SSL in Development:** SSL verification is disabled for development (self-signed Traefik certificates). Files: `config/initializers/00_openssl_dev.rb`, docker-compose env vars. **NEVER disable SSL verification in production!**
- **Custom OmniAuth Strategy:** Uses custom Keycloak strategy (`lib/omniauth/strategies/keycloak.rb`) for Keycloak 17+ compatibility, replacing `omniauth-keycloak` gem.
- **Frontend Bootstrap Integration:** The `application.ts` entrypoint imports Bootstrap CSS and JS, allowing use of Bootstrap components in Vue templates.
- **Database-backed Infrastructure:** Solid Cache, Queue, and Cable store state in the database—migrations exist in separate directories.
- **Modern Browser Requirement:** ApplicationController enforces modern browser support (webp, push notifications, etc.).
- **Credentials Management:** Use `bin/rails credentials:edit` to manage encrypted secrets.
- **Parallel Testing:** Tests run in parallel automatically; override in test_helper.rb if needed.
- **Docker in WSL:** Project designed to work from WSL with Docker Desktop. All hostnames use `localtest.me` which resolves to 127.0.0.1.
- **Vite HMR in Docker:** WebSocket HMR connects directly to `localhost:3036` (not via Traefik). This works because the browser can reach the Vite dev server directly on that port through Docker's port mapping.
