# How mod_auth_openidc Works - OIDC Authentication Flow

## What is `mod_auth_openidc`?

`mod_auth_openidc` is an Apache HTTP Server module that implements OpenID Connect (OIDC) authentication. It acts as an OIDC Relying Party (RP) and handles:
- User authentication via an Identity Provider (Keycloak)
- Token management (ID tokens, access tokens)
- Session management
- Claim extraction from tokens

## The OIDC Authentication Flow

### Initial Request (User Not Authenticated)

1. **User requests**: `https://localhost:8443/user`
2. **Apache receives the request** and `mod_auth_openidc` intercepts it
3. **The `<Location /user>` block** has `AuthType openid-connect` and `Require valid-user`, so authentication is required
4. **No valid session found** → user is redirected to Keycloak

### Keycloak Redirect (Authorization Code Flow)

5. **Apache redirects to**:
   ```
   https://localhost/realms/demo/protocol/openid-connect/auth?
     client_id=quarkus-app
     &redirect_uri=https://localhost:8443/redirect_uri
     &response_type=code
     &scope=openid profile email
   ```
   - Uses `OIDCProviderAuthorizationEndpoint` (external URL for browser)
   - Includes `client_id`, `redirect_uri`, and other OAuth2 parameters

6. **User authenticates** with Keycloak (username/password)

7. **Keycloak redirects back to**:
   ```
   https://localhost:8443/redirect_uri?code=AUTHORIZATION_CODE&state=STATE
   ```

### Token Exchange (Backend)

8. **Apache receives the callback** at `/redirect_uri`
9. **The `<Location /redirect_uri>` block** handles the callback
10. **`mod_auth_openidc` exchanges the authorization code for tokens**:
    - Uses `OIDCProviderTokenEndpoint` (internal URL: `https://keycloak:8443/...`)
    - Sends `client_id`, `client_secret`, and the authorization code
    - Receives:
      - **ID Token** (JWT with user claims)
      - **Access Token** (for API calls)
      - **Refresh Token** (optional)

11. **`mod_auth_openidc` validates the ID token**:
    - Verifies signature using JWKS from `OIDCProviderJwksUri`
    - Checks expiration, issuer, audience
    - Decodes claims (username, email, etc.)

12. **Session creation**:
    - Creates an encrypted session cookie (using `OIDCCryptoPassphrase`)
    - Stores token information in the session
    - Subsequent requests use this session (no re-authentication needed until expiry)

### Subsequent Request (User Authenticated)

13. **User makes another request** to `/user`
14. **`mod_auth_openidc` finds the session cookie**
15. **Session is valid** → authentication passes
16. **Request header is set**:
    ```apache
    RequestHeader set X-User-Id "%{OIDC_CLAIM_preferred_username}e"
    ```
    - Extracts `preferred_username` from the ID token claims
    - Sets it as `X-User-Id` header

17. **Request is proxied to Quarkus**:
    ```apache
    ProxyPass /user http://quarkus-app:8080/user
    ```
    - Quarkus receives the request with `X-User-Id` header
    - Quarkus reads the header and returns the user ID as JSON

## Key Configuration Directives Explained

```apache
OIDCProviderMetadataURL https://keycloak:8443/realms/demo/.well-known/openid-configuration
```
- Fetches OIDC discovery document (auto-discovers endpoints)
- Uses internal DNS name since Apache runs in the same network

```apache
OIDCProviderAuthorizationEndpoint https://localhost/realms/demo/protocol/openid-connect/auth
```
- Overrides the authorization endpoint
- Uses external URL (`localhost` on port 443, the default HTTPS port) so the browser can reach it

```apache
OIDCProviderTokenEndpoint https://keycloak:8443/realms/demo/protocol/openid-connect/token
```
- Token exchange endpoint
- Uses internal DNS (`keycloak`) since it's server-to-server

```apache
OIDCRedirectURI https://localhost:8443/redirect_uri
```
- Where Keycloak redirects after authentication (Apache on port 8443)
- Must match one of the redirect URIs configured in Keycloak client

```apache
AuthType openid-connect
Require valid-user
```
- Enables OIDC authentication for the location
- `valid-user` means any authenticated user can access

## Flow Diagram

```
Browser → Apache → Keycloak (login)
              ↓
         [No Session]
              ↓
    [Redirect to Keycloak]
              ↓
    [User Authenticates]
              ↓
    [Keycloak Redirects with Code]
              ↓
    [Apache Exchanges Code for Tokens]
              ↓
    [Session Created]
              ↓
    [Request Header Set: X-User-Id]
              ↓
    [Proxied to Quarkus]
              ↓
    [Quarkus Returns JSON]
```

## Why This Architecture?

1. **Centralized Authentication**: Apache handles OIDC; backend apps don't need OIDC logic
2. **Security**: Backend only sees authenticated requests; no tokens in the app
3. **Flexibility**: Backend can use custom headers (e.g., `X-User-Id`) instead of parsing tokens
4. **Performance**: Session caching avoids token validation on every request

This is a **reverse proxy authentication pattern**: Apache handles authentication, and the backend receives authenticated requests with user information in headers.

