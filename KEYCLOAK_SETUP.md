# Keycloak OAuth2 Authentication Setup

Ce document décrit la configuration de l'authentification OAuth2 avec Keycloak pour l'application Rails.

## Architecture

- **Keycloak**: Serveur d'identité accessible via `https://keycloak.localtest.me` (Traefik reverse proxy)
- **Rails**: Application accessible via `https://rails.localtest.me`
- **Base de données**: PostgreSQL séparée pour Keycloak (`keycloak_development`)
- **Stratégie OAuth2**: Custom OmniAuth strategy (compatible Keycloak 17+)

## Configuration Keycloak

### Étape 1: Accéder à l'Admin Console

1. URL: **https://keycloak.localtest.me**
2. Username: `admin`
3. Password: `admin`

### Étape 2: Créer le Realm

1. Cliquer sur le dropdown en haut à gauche (affiche "master")
2. Cliquer "Create Realm"
3. Name: `rails-base`
4. Cliquer "Create"

### Étape 3: Créer le Client OAuth2

1. Menu gauche → "Clients" → "Create client"

**General Settings:**
- Client type: `OpenID Connect`
- Client ID: `rails-base-app`
- Cliquer "Next"

**Capability config:**
- Client authentication: `ON` (confidential client)
- Authorization: `OFF`
- Authentication flow: Cocher `Standard flow` et `Direct access grants`
- Cliquer "Next"

**Login settings:**
- Root URL: `https://rails.localtest.me`
- Home URL: `https://rails.localtest.me`
- Valid redirect URIs: `https://rails.localtest.me/auth/keycloak/callback`
- **Valid post logout redirect URIs**: `https://rails.localtest.me/*` (Important pour le full logout\!)
- Web origins: `https://rails.localtest.me`
- Cliquer "Save"

**⚠️ Important**: N'oubliez pas de configurer "Valid post logout redirect URIs" sinon le full logout ne fonctionnera pas\!

### Étape 4: Récupérer le Client Secret

1. Aller dans l'onglet "Credentials" du client
2. Copier la valeur "Client Secret"
3. Mettre à jour le fichier `.env`:
   ```bash
   KEYCLOAK_CLIENT_SECRET=<coller-le-secret-ici>
   ```
4. Recréer le service web (restart ne suffit pas):
   ```bash
   docker compose up -d --force-recreate web
   ```

### Étape 5: Créer un Client API (Optionnel - Pour l'API JWT)

**Note**: Cette étape est optionnelle et nécessaire uniquement si vous souhaitez utiliser l'authentification API avec JWT (service-to-service).

1. Menu gauche → "Clients" → "Create client"

**General Settings:**
- Client type: `OpenID Connect`
- Client ID: `rails-api-client`
- Cliquer "Next"

**Capability config:**
- Client authentication: `ON` (confidential client)
- Authorization: `OFF`
- Authentication flow: Cocher uniquement `Service accounts roles`
- **Décocher** les autres flows (Standard flow, Direct access grants, etc.)
- Cliquer "Next"

**Login settings:**
- Laisser vide (pas de redirect URLs pour service accounts)
- Cliquer "Save"

**Récupérer le Client Secret:**
1. Aller dans l'onglet "Credentials" du client
2. Copier la valeur "Client Secret"
3. Utiliser ce secret pour obtenir des JWT tokens via l'API

**Tester l'obtention de token:**
```bash
curl -X POST "https://keycloak.localtest.me/realms/rails-base/protocol/openid-connect/token" \
  -d "grant_type=client_credentials" \
  -d "client_id=rails-api-client" \
  -d "client_secret=<votre-client-secret>"
```

**Configurer les informations utilisateur (Important pour l'API):**

Par défaut, les service accounts n'ont pas d'email ou de nom. Pour que l'API Rails puisse créer des utilisateurs, il faut configurer ces informations:

1. Menu gauche → "Users"
2. Chercher l'utilisateur `service-account-rails-api-client`
3. Cliquer dessus pour l'éditer
4. Remplir les champs:
   - Email: `api@rails-base.local`
   - First name: `Rails API`
   - Last name: `Service`
   - Email verified: `ON`
5. Cliquer "Save"

**Alternative: Utiliser le Password Flow avec un utilisateur réel**

Pour tester l'API avec un utilisateur réel, vous pouvez utiliser le Password Flow:
```bash
curl -X POST "https://keycloak.localtest.me/realms/rails-base/protocol/openid-connect/token" \
  -d "grant_type=password" \
  -d "client_id=rails-base-app" \
  -d "client_secret=<client-secret>" \
  -d "username=testuser" \
  -d "password=testpassword"
```

**Note de sécurité**: Le Password Flow n'est pas recommandé en production. Utilisez plutôt le Client Credentials Flow pour les services ou l'Authorization Code Flow pour les applications utilisateur.

### Étape 6: Créer un Utilisateur de Test

1. Menu gauche → "Users" → "Create new user"
2. Remplir les champs:
   - Username: `testuser`
   - Email: `testuser@localtest.me`
   - First name: `Test`
   - Last name: `User`
   - Email verified: `ON`
3. Cliquer "Create"
4. Aller dans l'onglet "Credentials"
5. Cliquer "Set password"
6. Entrer le mot de passe: `testpassword`
7. Temporary: `OFF`
8. Cliquer "Save"

## API Authentication (JWT)

L'application supporte également l'authentification API via JWT tokens pour les services et applications mobiles.

**Documentation complète**: Voir [API.md](API.md) pour tous les détails.

**Résumé rapide:**

1. **Obtenir un JWT token** depuis Keycloak:
   ```bash
   curl -X POST "https://keycloak.localtest.me/realms/rails-base/protocol/openid-connect/token" \
     -d "grant_type=client_credentials" \
     -d "client_id=rails-api-client" \
     -d "client_secret=<votre-client-secret>"
   ```

2. **Utiliser le token** pour appeler l'API:
   ```bash
   curl -X GET "https://rails.localtest.me/api/v1/users/me" \
     -H "Authorization: Bearer <votre-token>"
   ```

**Architecture:**
- **Backend**: Les tokens JWT sont validés en utilisant les clés publiques JWKS de Keycloak
- **Stateless**: Aucune session Rails, authentification pure par token
- **Auto-création**: Les utilisateurs sont automatiquement créés/mis à jour depuis les claims JWT
- **Cache JWKS**: Les clés publiques sont mises en cache pendant 1 heure pour la performance

**Endpoints disponibles:**
- `GET /api/v1/users/me` - Retourne les informations de l'utilisateur actuel

## Test du Flux OAuth2 (Browser)

### Test du Login

1. Ouvrir **https://rails.localtest.me**
2. Cliquer sur "Sign in" dans la navbar
3. Se connecter avec `testuser` / `testpassword`
4. Redirection vers Rails avec l'utilisateur connecté
5. La navbar affiche le nom de l'utilisateur avec un menu dropdown

### Test du Signup

1. Ouvrir **https://rails.localtest.me** (en mode navigation privée ou après logout)
2. Cliquer sur "Sign up" dans la navbar
3. Le formulaire d'inscription Keycloak s'affiche directement
4. Créer un nouveau compte
5. Redirection vers Rails avec le nouvel utilisateur connecté

### Inscription (Sign up)

Le bouton "Sign up" dans la navbar redirige directement vers le formulaire d'inscription Keycloak.

**Comment ça marche:**
1. Le bouton envoie une requête POST vers `/auth/keycloak` avec le paramètre `kc_action=register`
2. La stratégie personnalisée détecte ce paramètre dans `request_phase`
3. Au lieu d'utiliser l'endpoint `/protocol/openid-connect/auth`, elle bascule vers `/protocol/openid-connect/registrations`
4. L'utilisateur voit directement le formulaire d'inscription Keycloak
5. Après inscription, redirection vers Rails avec l'utilisateur connecté

**Note technique:** Keycloak 17+ ignore le paramètre `kc_action=REGISTER` sur l'endpoint `/auth`. La solution est d'utiliser l'endpoint dédié `/registrations` qui affiche directement le formulaire d'inscription.

### Options de Déconnexion

- **Logout (Session Only)**: Déconnexion de Rails uniquement (rapide, reste connecté sur Keycloak)
- **Full Logout (Keycloak)**: Déconnexion complète de Rails ET Keycloak (avec redirection)

## Variables d'Environnement

Fichier `.env` configuré:

```bash
# Keycloak Database
KEYCLOAK_DB=keycloak_development

# Keycloak Admin
KEYCLOAK_ADMIN=admin
KEYCLOAK_ADMIN_PASSWORD=admin

# OAuth2 Configuration
KEYCLOAK_REALM=rails-base
KEYCLOAK_CLIENT_ID=rails-base-app
KEYCLOAK_CLIENT_SECRET=<secret-from-keycloak>
KEYCLOAK_SITE=https://keycloak.localtest.me
KEYCLOAK_REDIRECT_URI=https://rails.localtest.me/auth/keycloak/callback
```

**Important**: `KEYCLOAK_SITE` utilise l'URL externe HTTPS. Grâce à `extra_hosts` dans docker-compose.yml, le container Rails peut résoudre `keycloak.localtest.me` vers le service Keycloak via Traefik.

## Architecture des Fichiers

### Backend

- `app/models/user.rb` - Modèle User avec méthode `from_omniauth`
- `app/controllers/sessions_controller.rb` - Gestion du callback OAuth et déconnexion
- `app/controllers/application_controller.rb` - Helpers d'authentification (`current_user`, `authenticate_user\!`)
- `config/initializers/omniauth.rb` - Configuration OmniAuth avec stratégie personnalisée
- `lib/omniauth/strategies/keycloak.rb` - **Stratégie OAuth2 personnalisée pour Keycloak 17+**
- `config/initializers/00_openssl_dev.rb` - Désactivation SSL verification en développement
- `config/routes.rb` - Routes d'authentification

### Frontend

- `app/views/layouts/application.html.erb` - UI de connexion/déconnexion dans la navbar

### Infrastructure

- `docker-compose.yml` - Service Keycloak avec configuration proxy, extra_hosts, et variables SSL
- `.env` - Variables d'environnement OAuth2

## Pourquoi une Stratégie Personnalisée ?

Le gem `omniauth-keycloak` a des problèmes de compatibilité avec Keycloak 17+ car il essaie d'utiliser l'ancien chemin `/auth/` qui n'existe plus. Nous avons créé une stratégie personnalisée basée sur `omniauth-oauth2` qui:

- ✅ Utilise les bons endpoints Keycloak 17+ (sans `/auth/`)
- ✅ Configure explicitement tous les endpoints OAuth2
- ✅ Gère correctement les informations utilisateur (email, nom, etc.)
- ✅ Supporte l'inscription (signup) en basculant dynamiquement vers `/registrations`
- ✅ Plus simple et plus maintenable

**Endpoints configurés:**
```ruby
# Login (par défaut)
authorize_url: "/realms/rails-base/protocol/openid-connect/auth"

# Inscription (quand kc_action=register)
authorize_url: "/realms/rails-base/protocol/openid-connect/registrations"

# Commun
token_url: "/realms/rails-base/protocol/openid-connect/token"
userinfo_url: "/realms/rails-base/protocol/openid-connect/userinfo"
```

**Gestion dynamique du signup:**
```ruby
def request_phase
  if request.params["kc_action"] == "register"
    session["omniauth.is_registration"] = true
    options.client_options.authorize_url = "/realms/#{ENV["KEYCLOAK_REALM"]}/protocol/openid-connect/registrations"
  else
    options.client_options.authorize_url = "/realms/#{ENV["KEYCLOAK_REALM"]}/protocol/openid-connect/auth"
    session["omniauth.is_registration"] = false
  end
  super
end
```

## Configuration Docker Spécifique

### extra_hosts dans docker-compose.yml

```yaml
web:
  extra_hosts:
    - "keycloak.localtest.me:host-gateway"
```

Ceci permet au container Rails de résoudre `keycloak.localtest.me` vers l'hôte Docker, qui route ensuite via Traefik vers Keycloak.

### Variables SSL (Développement uniquement)

```yaml
environment:
  SSL_CERT_FILE: /dev/null
  RUBY_NET_HTTP_SSL_VERIFY_PEER: "false"
```

Ces variables désactivent la vérification SSL pour accepter le certificat auto-signé de Traefik en développement.

### Initializer OpenSSL (00_openssl_dev.rb)

```ruby
if Rails.env.development?
  OpenSSL::SSL.send(:remove_const, :VERIFY_PEER)
  OpenSSL::SSL::VERIFY_PEER = OpenSSL::SSL::VERIFY_NONE
end
```

Désactive globalement la vérification SSL en développement (à ne JAMAIS faire en production\!).

## Commandes Utiles

```bash
# Vérifier le statut des services
docker compose ps

# Voir les logs Keycloak
docker compose logs -f keycloak

# Voir les logs Rails
docker compose logs -f web

# Ouvrir la console Rails
docker compose exec web bin/rails console

# Vérifier les utilisateurs en base
docker compose exec web bin/rails runner "puts User.all.to_json"

# Recréer le service web (nécessaire après changement .env)
docker compose up -d --force-recreate web

# Redémarrer tous les services
docker compose restart
```

## Dépannage

### Erreur "SSL certificate verify failed"

**Symptôme**: Erreur SSL lors de la connexion OAuth

**Solution**: Vérifier que ces éléments sont configurés:
1. Variables d'environnement SSL dans docker-compose.yml
2. Fichier `config/initializers/00_openssl_dev.rb` existe
3. Recréer le container: `docker compose up -d --force-recreate web`

### Erreur "Page not found" sur Keycloak avec `/auth/` dans l'URL

**Symptôme**: URLs Keycloak contiennent `/auth/realms/...`

**Solution**: Vous utilisez probablement encore `omniauth-keycloak`. Vérifiez:
1. Le Gemfile ne doit PAS contenir `gem "omniauth-keycloak"`
2. Le fichier `lib/omniauth/strategies/keycloak.rb` doit exister
3. L'initializer OmniAuth charge la stratégie personnalisée

### Erreur "Invalid redirect uri" lors du full logout

**Symptôme**: Keycloak refuse la redirection après logout

**Solution**: Dans Keycloak, configurer "Valid post logout redirect URIs":
```
https://rails.localtest.me/*
```

### Le bouton "Sign up" mène à la page de login au lieu de l'inscription

**Symptôme**: Cliquer sur "Sign up" affiche le formulaire de login Keycloak avec un lien "Register" en bas, au lieu d'afficher directement le formulaire d'inscription.

**Cause**: Keycloak 17+ (Quarkus) ignore le paramètre `kc_action=REGISTER` sur l'endpoint `/protocol/openid-connect/auth`.

**Solution**: Utiliser l'endpoint dédié `/protocol/openid-connect/registrations` au lieu de l'endpoint `/auth` avec le paramètre `kc_action`. La stratégie personnalisée dans `lib/omniauth/strategies/keycloak.rb` gère automatiquement cette bascule dans la méthode `request_phase`:

```ruby
def request_phase
  if request.params["kc_action"] == "register"
    session["omniauth.is_registration"] = true
    options.client_options.authorize_url = "/realms/#{ENV["KEYCLOAK_REALM"]}/protocol/openid-connect/registrations"
  else
    options.client_options.authorize_url = "/realms/#{ENV["KEYCLOAK_REALM"]}/protocol/openid-connect/auth"
    session["omniauth.is_registration"] = false
  end
  super
end
```

**Vérification**: Après redémarrage de Rails (`docker compose restart web`), le bouton "Sign up" doit mener directement au formulaire d'inscription.

### Erreur "Mixed Content" dans le navigateur

**Symptôme**: Console browser affiche des erreurs HTTP/HTTPS

**Solution**: Vérifier la configuration Keycloak dans `docker-compose.yml`:
```yaml
KC_HOSTNAME_URL: https://keycloak.localtest.me
KC_HOSTNAME_ADMIN_URL: https://keycloak.localtest.me
KC_PROXY_HEADERS: xforwarded
```

### L'utilisateur n'est pas créé dans Rails

**Vérifications**:
1. Vérifier les logs Rails: `docker compose logs web | grep -i user`
2. Vérifier le callback dans SessionsController
3. Tester en console: `User.from_omniauth(auth_hash)`
4. Vérifier que la migration users a été exécutée: `docker compose exec web bin/rails db:migrate:status`

### Le container web ne démarre pas après changement .env

**Symptôme**: Le service web reste en état "Restarting"

**Solution**: Utiliser `--force-recreate` au lieu de `restart`:
```bash
docker compose up -d --force-recreate web
```

## Sécurité en Production

⚠️ **ATTENTION**: Cette configuration est pour le développement uniquement\!

Pour la production, modifier:

1. **Keycloak**:
   - Utiliser `start` au lieu de `start-dev`
   - Configurer des certificats HTTPS propres (Let's Encrypt)
   - Changer les mots de passe admin
   - Activer HTTPS strict (pas de HTTP)

2. **Rails**:
   - **SUPPRIMER** `config/initializers/00_openssl_dev.rb`
   - **SUPPRIMER** les variables SSL du docker-compose.yml
   - **ACTIVER** la vérification SSL normale
   - Chiffrer les tokens: `encrypts :token, :refresh_token` dans User model
   - Utiliser Rails credentials: `bin/rails credentials:edit`
   - Activer rate limiting sur les endpoints auth
   - Utiliser des certificats SSL valides

3. **Infrastructure**:
   - PostgreSQL externe (AWS RDS, etc.)
   - Backup régulier de la base Keycloak
   - Monitoring et logs centralisés
   - Reverse proxy avec certificats valides

## Ressources

- [Keycloak Documentation](https://www.keycloak.org/documentation)
- [Keycloak 17+ Migration Guide](https://www.keycloak.org/docs/latest/upgrading/index.html#migrating-to-quarkus-distribution)
- [OmniAuth Documentation](https://github.com/omniauth/omniauth)
- [OmniAuth OAuth2](https://github.com/omniauth/omniauth-oauth2)
