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
    - Quarkus reads the header and returns the user ID in an HTML page with a logout button

## The OIDC Logout Flow

### User Initiates Logout

1. **User clicks logout button** on the `/user` page
2. **Logout URL is constructed** by Quarkus:
   ```
   /redirect_uri?logout=https://localhost:8443/logged-out
   ```
   - The `logout` query parameter contains the post-logout redirect URI
   - This is URL-encoded by the Quarkus application

3. **User is redirected to** `/redirect_uri?logout=...`
4. **Apache receives the request** at `/redirect_uri` with the `logout` parameter
5. **`mod_auth_openidc` detects the logout parameter** and initiates logout

### Keycloak Logout

6. **`mod_auth_openidc` redirects to Keycloak logout endpoint**:
   ```
   https://localhost/realms/demo/protocol/openid-connect/logout?
     id_token_hint=ID_TOKEN
     &post_logout_redirect_uri=https://localhost:8443/logged-out
   ```
   - Uses the external URL (`localhost` on port 443) for browser redirect
   - Includes `id_token_hint` (the ID token from the session)
   - Includes `post_logout_redirect_uri` (where to redirect after logout)

7. **Keycloak processes the logout**:
   - Validates the `id_token_hint`
   - Invalidates the Keycloak session
   - Clears Keycloak cookies

8. **Keycloak redirects back to**:
   ```
   https://localhost:8443/logged-out
   ```

### Apache Session Cleanup

9. **Apache receives the redirect** to `/logged-out`
10. **`mod_auth_openidc` clears the Apache session**:
    - Invalidates the session cookie
    - Clears stored token information
    - User is no longer authenticated

11. **The `<Location /logged-out>` block** has `Require all granted`, so no authentication is required
12. **Request is proxied to Quarkus**:
    ```apache
    ProxyPass /logged-out http://quarkus-app:8080/logged-out
    ```
    - Quarkus serves the logged-out confirmation page
    - Page includes a link to log in again (redirects to `/user`)

### Subsequent Requests After Logout

13. **User attempts to access** `/user` again
14. **No valid session found** → user is redirected to Keycloak for authentication
15. **Flow repeats from the beginning**

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

```apache
<Location /logged-out>
    AuthType openid-connect
    Require all granted
</Location>
```
- Logged-out page is accessible without authentication
- `AuthType openid-connect` is still set to allow session cleanup
- `Require all granted` allows unauthenticated access

## Flow Diagrams

### Authentication Flow

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
    [Quarkus Returns HTML with Logout Button]
```

### Logout Flow

```
Browser → Apache (/redirect_uri?logout=...)
              ↓
    [mod_auth_openidc Detects Logout]
              ↓
    [Redirect to Keycloak Logout]
              ↓
    [Keycloak Invalidates Session]
              ↓
    [Keycloak Redirects to /logged-out]
              ↓
    [Apache Clears Session]
              ↓
    [Proxied to Quarkus]
              ↓
    [Quarkus Returns Logged-Out Page]
```

## Logout Implementation Details

### Quarkus Application Logout URL Construction

The Quarkus application constructs the logout URL in `UserResource.java`:

```java
String redirectUri = URLEncoder.encode("https://localhost:8443/logged-out", StandardCharsets.UTF_8);
String logoutUrl = "/redirect_uri?logout=" + redirectUri;
```

This creates a URL like: `/redirect_uri?logout=https%3A%2F%2Flocalhost%3A8443%2Flogged-out`

### Keycloak Logout Endpoint

Keycloak's logout endpoint requires:
- `id_token_hint`: The ID token from the current session (provided by `mod_auth_openidc`)
- `post_logout_redirect_uri`: Where to redirect after logout (must be in the client's allowed post-logout redirect URIs)

The logout endpoint URL:
```
https://localhost/realms/demo/protocol/openid-connect/logout
```

### Post-Logout Redirect URI Configuration

In Keycloak, the client must have the post-logout redirect URI configured. This can be set in the Keycloak admin console under:
- Client Settings → Valid post logout redirect URIs

Or configured in the realm JSON:
```json
{
  "attributes": {
    "post.logout.redirect.uris": "https://localhost:8443/logged-out"
  }
}
```

## Why This Architecture?

1. **Centralized Authentication**: Apache handles OIDC; backend apps don't need OIDC logic
2. **Security**: Backend only sees authenticated requests; no tokens in the app
3. **Flexibility**: Backend can use custom headers (e.g., `X-User-Id`) instead of parsing tokens
4. **Performance**: Session caching avoids token validation on every request
5. **Complete Session Management**: Both authentication and logout are handled by Apache, ensuring sessions are properly cleared on both sides

This is a **reverse proxy authentication pattern**: Apache handles authentication and logout, and the backend receives authenticated requests with user information in headers.

