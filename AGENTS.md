# AGENTS.md

## But du projet
- `docker-rails` est un socle Rails 8 avec frontend Vue 3/Bootstrap via Vite.
- Le projet expose une app web (session) et une API (JWT stateless) avec Keycloak.
- Le module métier principal actuel est `ArticlesRequest` avec des `Article` imbriqués et upload de fichiers via Shrine.

## Stack et versions
- Ruby: `3.3.10` (`.ruby-version`)
- Rails: `8.1.x`
- Base de données: PostgreSQL `16`
- Cache/queue/cable: `solid_cache`, `solid_queue`, `solid_cable`
- Frontend: Vue `3`, Bootstrap `5`, Vite `6`, TypeScript
- Auth: Devise + OmniAuth + Keycloak (OIDC), JWT (JWKS RS256) pour l'API
- Infra locale: Docker Compose (web, vite, db, redis, keycloak, pgadmin)

## Démarrage local (recommandé)
1. Créer `.env` avec au minimum `POSTGRES_PASSWORD`.
2. Lancer: `docker compose up -d`
3. Préparer DB: `docker compose exec web bin/rails db:prepare`
4. Ouvrir l'app: `https://rails.localtest.me`
5. Ouvrir Keycloak: `https://keycloak.localtest.me`
6. Ouvrir PgAdmin: `https://pgadmin.localtest.me`

## Commandes de travail
- Console Rails: `docker compose exec web bin/rails console`
- Tests: `docker compose exec web bin/rails test`
- Rubocop: `docker compose exec web bundle exec rubocop`
- Brakeman: `docker compose exec web bundle exec brakeman`
- Bundler audit: `docker compose exec web bundle exec bundler-audit`
- Typecheck Vue/TS: `docker compose exec web pnpm run vue-tsc --noEmit`
- Logs Rails: `docker compose logs -f web`
- Logs Vite: `docker compose logs -f vite`
- Logs Keycloak: `docker compose logs -f keycloak`

## Architecture à connaître
- Routes: `config/routes.rb`
- Auth web: `app/controllers/users/omniauth_callbacks_controller.rb`
- Auth web: `app/controllers/users/sessions_controller.rb`
- Auth API JWT: `app/controllers/api/base_controller.rb`
- Auth API JWT: `app/controllers/concerns/api_authenticatable.rb`
- Auth API JWT: `app/services/keycloak_jwt_validator.rb`
- Domaine: `app/models/articles_request.rb`
- Domaine: `app/models/articles_request/article.rb`
- Domaine: `app/controllers/articles_requests_controller.rb`
- Frontend: `app/javascript/entrypoints/application.ts`
- Frontend: `app/javascript/utils/vue-mounter.ts`
- Frontend: `app/javascript/controllers/*`
- Upload: `app/views/shared/_file_upload.html.erb` + `file_upload_controller.js`

## Conventions de contribution
- Faire des changements ciblés, minimaux, et compatibles avec le style existant.
- Préférer `simple_form` côté formulaires Rails.
- Conserver le pattern Stimulus pour comportements DOM (nested form, upload, etc.).
- Ne pas casser le montage Vue basé sur `data-behavior="vue-*"`.
- API: toujours renvoyer du JSON et des statuts HTTP cohérents.
- Ne jamais committer de secrets.
- Ne pas désactiver de vérification SSL hors contexte dev local.
- Conserver la validation JWT (issuer, signature, algo RS256).

## Zones sensibles
- Authentification Keycloak (flows login/signup/logout, callback OAuth).
- Validation JWT/JWKS (impact API globale).
- Upload Shrine (`attachment_data`, cache/promotion).
- Configuration Docker/Traefik (`docker-compose.yml`, hosts locaux).

## Définition de terminé (Definition of Done)
1. Le code répond au besoin sans régression fonctionnelle évidente.
2. Les tests pertinents passent (au minimum ceux de la zone touchée).
3. Si frontend touché: vérification visuelle rapide + typecheck TS si concerné.
4. Aucun secret ajouté, aucune config sensible exposée.
5. Les changements sont lisibles et limités au périmètre demandé.

## Comment demander une tâche efficacement à l'agent
- Donner l'objectif fonctionnel attendu.
- Donner le périmètre fichiers/features.
- Donner les contraintes techniques (perf, sécurité, style, compatibilité).
- Donner des critères d'acceptation testables.
- Exemple utile:
- "Ajouter `GET /api/v1/...`, sécuriser avec JWT existant, ajouter tests contrôleur, ne pas modifier les flows Devise/Keycloak web."
