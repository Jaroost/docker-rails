# API Documentation

This document describes how to use the Rails Base API with JWT authentication via Keycloak.

## Authentication

The API uses **stateless JWT authentication**. All API requests must include a valid JWT token in the `Authorization` header.

### How It Works

1. **Obtain JWT Token**: Get a JWT token from Keycloak using OAuth 2.0 flows
2. **Make API Request**: Include the token in the `Authorization: Bearer <token>` header
3. **Token Validation**: Rails validates the token using Keycloak's public keys (JWKS)
4. **User Identification**: User is identified/created from JWT claims

### Supported OAuth 2.0 Flows

#### 1. Client Credentials Flow (Service-to-Service)

Best for backend services and machine-to-machine communication.

```bash
# Step 1: Obtain access token from Keycloak
curl -X POST "https://keycloak.localtest.me/realms/rails-base/protocol/openid-connect/token" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "grant_type=client_credentials" \
  -d "client_id=YOUR_CLIENT_ID" \
  -d "client_secret=YOUR_CLIENT_SECRET"

# Response:
{
  "access_token": "eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9...",
  "expires_in": 300,
  "token_type": "Bearer"
}

# Step 2: Use the access token to call the API
curl -X GET "https://rails.localtest.me/api/v1/users/me" \
  -H "Authorization: Bearer eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9..."
```

#### 2. Password Flow (Direct Access)

Best for trusted applications like mobile apps. **Not recommended for production** - use Authorization Code Flow instead.

```bash
# Obtain access token with username and password
curl -X POST "https://keycloak.localtest.me/realms/rails-base/protocol/openid-connect/token" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "grant_type=password" \
  -d "client_id=YOUR_CLIENT_ID" \
  -d "client_secret=YOUR_CLIENT_SECRET" \
  -d "username=user@example.com" \
  -d "password=userpassword"
```

#### 3. Authorization Code Flow (Web/Mobile Apps)

Best for web and mobile applications. Requires browser-based OAuth flow.

See [KEYCLOAK_SETUP.md](KEYCLOAK_SETUP.md) for detailed setup instructions.

## API Endpoints

### Base URL

```
https://rails.localtest.me/api/v1
```

### Authentication Required

All API endpoints require authentication via JWT token.

---

### GET /api/v1/users/me

Returns the current user's profile information from the JWT token.

**Request:**

```bash
curl -X GET "https://rails.localtest.me/api/v1/users/me" \
  -H "Authorization: Bearer <your_jwt_token>"
```

**Response (200 OK):**

```json
{
  "id": 1,
  "email": "user@example.com",
  "username": "user",
  "first_name": "John",
  "last_name": "Doe",
  "provider": "keycloak",
  "created_at": "2026-02-14T20:00:00.000Z",
  "updated_at": "2026-02-14T20:15:00.000Z"
}
```

**Error Response (401 Unauthorized):**

```json
{
  "error": "Missing Authorization header"
}
```

or

```json
{
  "error": "Invalid or expired token: <error_message>"
}
```

---

## Error Handling

The API returns standard HTTP status codes:

| Status Code | Description |
|-------------|-------------|
| 200 | Success |
| 401 | Unauthorized - Missing or invalid JWT token |
| 404 | Not Found - Endpoint does not exist |
| 500 | Internal Server Error |

### Error Response Format

All error responses follow this format:

```json
{
  "error": "Error message describing what went wrong"
}
```

## JWT Token Structure

JWT tokens issued by Keycloak contain the following claims:

```json
{
  "exp": 1645123456,              // Expiration timestamp
  "iat": 1645120000,              // Issued at timestamp
  "iss": "https://keycloak.localtest.me/realms/rails-base",
  "sub": "abc123-def456-...",     // Subject (User ID)
  "email": "user@example.com",
  "email_verified": true,
  "preferred_username": "user",
  "given_name": "John",
  "family_name": "Doe"
}
```

The Rails API automatically creates or updates users based on these JWT claims.

## Token Validation

The API validates JWT tokens using Keycloak's JWKS (JSON Web Key Set):

1. **Signature Verification**: Token is signed with Keycloak's private key and verified with the public key from JWKS
2. **Expiration Check**: Token must not be expired (exp claim)
3. **Issuer Validation**: Token must be issued by the configured Keycloak realm
4. **Algorithm Check**: Only RS256 algorithm is accepted

JWKS is cached for 1 hour to improve performance and reduce requests to Keycloak.

## Testing with curl

### 1. Without Token (401 Error)

```bash
curl -X GET "https://rails.localtest.me/api/v1/users/me"
# Response: {"error":"Missing Authorization header"}
```

### 2. With Invalid Token (401 Error)

```bash
curl -X GET "https://rails.localtest.me/api/v1/users/me" \
  -H "Authorization: Bearer invalid_token"
# Response: {"error":"Invalid or expired token: Not enough or too many segments"}
```

### 3. With Valid Token (200 Success)

```bash
# First, obtain a token from Keycloak
TOKEN=$(curl -s -X POST "https://keycloak.localtest.me/realms/rails-base/protocol/openid-connect/token" \
  -d "grant_type=client_credentials" \
  -d "client_id=YOUR_CLIENT_ID" \
  -d "client_secret=YOUR_CLIENT_SECRET" | jq -r '.access_token')

# Then use the token to call the API
curl -X GET "https://rails.localtest.me/api/v1/users/me" \
  -H "Authorization: Bearer $TOKEN"
```

## Security Considerations

### Token Storage

- **Never** store JWT tokens in localStorage or cookies in the browser (XSS vulnerability)
- Use secure HTTP-only cookies or memory storage for web apps
- For mobile apps, use secure device storage (Keychain on iOS, KeyStore on Android)

### Token Expiration

- Keycloak tokens expire after a configured duration (default: 5 minutes)
- Implement token refresh logic in your client application
- Use refresh tokens to obtain new access tokens without re-authentication

### HTTPS Only

- **Always** use HTTPS in production
- JWT tokens transmitted over HTTP can be intercepted

### Rate Limiting

- Consider implementing rate limiting on API endpoints
- Prevent abuse and brute force attacks

## Client Libraries

### JavaScript/TypeScript

```typescript
const token = 'your_jwt_token';

const response = await fetch('https://rails.localtest.me/api/v1/users/me', {
  method: 'GET',
  headers: {
    'Authorization': `Bearer ${token}`,
    'Content-Type': 'application/json'
  }
});

const data = await response.json();
console.log(data);
```

### Ruby

```ruby
require 'net/http'
require 'json'

token = 'your_jwt_token'
uri = URI('https://rails.localtest.me/api/v1/users/me')

request = Net::HTTP::Get.new(uri)
request['Authorization'] = "Bearer #{token}"

response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
  http.request(request)
end

data = JSON.parse(response.body)
puts data
```

### Python

```python
import requests

token = 'your_jwt_token'
headers = {'Authorization': f'Bearer {token}'}

response = requests.get(
    'https://rails.localtest.me/api/v1/users/me',
    headers=headers
)

data = response.json()
print(data)
```

## Next Steps

1. **Set up Keycloak Client**: See [KEYCLOAK_SETUP.md](KEYCLOAK_SETUP.md) for instructions
2. **Obtain JWT Token**: Use one of the OAuth 2.0 flows described above
3. **Call API Endpoints**: Include the token in the Authorization header
4. **Handle Errors**: Implement proper error handling for 401 responses

## Support

For issues or questions:
- Check [KEYCLOAK_SETUP.md](KEYCLOAK_SETUP.md) for Keycloak configuration
- Check [CLAUDE.md](CLAUDE.md) for project architecture
- Review Rails logs: `docker compose logs web`
