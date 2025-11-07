# Keycloak OIDC with Quarkus and Apache HTTP Server

This project demonstrates a containerized application using:
- **Quarkus** application that displays user ID from HTTP headers
- **Keycloak** server for OIDC authentication
- **Apache HTTP Server** with `mod_auth_openidc` as a reverse proxy
- **Podman** for containerization

## Architecture

1. **Apache HTTP Server** acts as a reverse proxy with OIDC authentication (HTTPS on port 8443)
2. **Keycloak** provides OIDC authentication services (HTTPS on port 443)
3. **Quarkus** application receives authenticated requests with user ID in headers (HTTP on port 8081)
4. **PostgreSQL** database for Keycloak

All services communicate over an internal Docker network, with Apache and Keycloak exposing HTTPS endpoints externally.

## Prerequisites

- Podman installed
- Podman Compose installed
- Maven 3.8+ (for building Quarkus app)

## Setup Instructions

### 1. Build the Quarkus Application

```bash
cd quarkus-app
mvn clean package
cd ..
```

### 2. Generate SSL Certificates

Generate self-signed certificates for HTTPS:

```bash
# Generate certificates for Apache
./apache/generate-certs.sh

# Generate certificates for Keycloak
./keycloak/generate-certs.sh
```

### 3. Update Keycloak Client Secret

Edit `apache/httpd-oidc.conf` and `keycloak/realm-config.json` to set a secure client secret:
- Replace `your-client-secret-here` with your actual secret in both files

### 4. Start the Services

```bash
podman compose up -d
```

Or using the podman-compose binary:
```bash
podman-compose up -d
```

### 5. Access the Application

- **Application**: https://localhost:8443/user
- **Keycloak Admin Console**: https://localhost/
  - Username: `admin`
  - Password: `admin`

## Default Test User

- Username: `testuser`
- Password: `testpassword`

## How It Works

1. User accesses https://localhost:8443/user
2. Apache HTTP Server with `mod_auth_openidc` intercepts the request
3. If not authenticated, user is redirected to Keycloak login
4. After authentication, Keycloak redirects back to Apache
5. Apache exchanges the authorization code for tokens and validates them
6. Apache extracts the user ID from OIDC claims and sets the `X-User-Id` header
7. Request is proxied to the Quarkus application
8. Quarkus application reads the `X-User-Id` header and returns it as JSON

For a detailed explanation of the OIDC authentication flow, see [OIDC_FLOW.md](OIDC_FLOW.md).

For a detailed explanation of application of a common theme to the Quarkus application and Keycloak pages, see [THEMING.md](THEMING.md).

## Configuration

### Apache OIDC Configuration

The Apache configuration in `apache/httpd-oidc.conf`:
- Connects to Keycloak OIDC provider
- Protects `/user` endpoint
- Extracts `preferred_username` claim and sets it as `X-User-Id` header
- Proxies requests to Quarkus application

### Keycloak Realm

The Keycloak realm configuration in `keycloak/realm-config.json`:
- Creates a `demo` realm
- Sets up a test user
- Configures the `quarkus-app` client

## Troubleshooting

### Check Service Logs

```bash
podman compose logs keycloak
podman compose logs apache
podman compose logs quarkus-app
```

### Verify Keycloak is Running

```bash
curl -k https://localhost/realms/demo/.well-known/openid-configuration
```

Note: The `-k` flag is used to skip SSL certificate verification (self-signed certificates).

### Rebuild Services

```bash
podman compose down
podman compose build --no-cache
podman compose up -d
```

## Security Notes

- Change the default admin password for Keycloak in production
- Use secure client secrets
- Update `OIDCCryptoPassphrase` in Apache configuration
- **HTTPS is enabled by default** - the configuration uses self-signed certificates for development
- In production, replace self-signed certificates with certificates from a trusted CA
- Review and adjust OIDC session timeouts
- Consider enabling `OIDCSSLValidateServer` in production (currently disabled for self-signed certs)

## Stopping the Services

```bash
podman compose down
```

To remove volumes:
```bash
podman compose down -v
```

