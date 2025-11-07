# Theme Customization Guide

This document explains how the ACME Company theme is configured and deployed across the application.

## Overview

The application uses a consistent ACME Company theme across three main pages:
1. **Keycloak Login Page** - Custom theme using Keycloak's theming system
2. **User Info Page** - Quarkus application page showing user information
3. **Logged Out Page** - Quarkus application page shown after logout

All pages share the same color scheme, typography, and styling to provide a cohesive user experience.

## Keycloak Login Page Theme

### Theme Structure

The Keycloak theme is located in `keycloak/themes/acme-theme/` with the following structure:

```
acme-theme/
└── login/
    ├── theme.properties         # Login theme configuration
    ├── login.ftl                # Custom FreeMarker template
    └── resources/
        └── css/
            └── custom.css       # Custom CSS styles
```

### Theme Configuration

#### Login Theme (`login/theme.properties`)

```properties
parent=keycloak.v2
import=common/keycloak
styles=css/custom.css
```

This configuration:
- Sets the parent theme to `keycloak.v2` (Keycloak's v2 theme system)
- Imports common Keycloak resources
- Specifies the custom CSS file to load: `css/custom.css`

### Custom FreeMarker Template

The login page uses a custom FreeMarker template (`login/login.ftl`) that extends Keycloak's registration layout:

```freemarker
<#import "template.ftl" as layout>
<@layout.registrationLayout ...>
    <#if section = "header">
        <div class="kc-login-header">
            <h1>Test Application</h1>
        </div>
    <#elseif section = "form">
        <!-- Login form content -->
    </#if>
</@layout.registrationLayout>
```

The template customizes:
- **Header section**: Displays the page title (currently "Test Application" in the template) with custom styling
- **Form section**: Uses Keycloak's standard form structure but with custom CSS

### Custom CSS Styling

The `login/resources/css/custom.css` file contains all the custom styles for the login page. The CSS file:
- Defines CSS variables for the color scheme
- Styles the container layout to match the Quarkus application pages
- Customizes form inputs, buttons, and other UI elements
- Uses CSS variables for consistent theming across all pages

### Realm Configuration

The theme is applied to the realm in `keycloak/realm-config.json`:

```json
{
  "realm": "demo",
  "loginTheme": "acme-theme",
  ...
}
```

## Quarkus Application Pages

### Shared CSS File

The Quarkus application uses a shared CSS file located at:
```
quarkus-app/src/main/resources/META-INF/resources/acme-theme.css
```

This file is automatically served by Quarkus at `/acme-theme.css` and contains all the shared styles for the user-info and logged-out pages.

### HTML Templates

Both the user info page (`user-info.html`) and logged out page (`logged-out.html`) reference the shared CSS:

```html
<link rel="stylesheet" href="/acme-theme.css">
```

The templates use placeholder replacement to inject dynamic content (user ID, logout URL, login URL).

### Apache Proxy Configuration

The Apache HTTP Server is configured to proxy CSS requests to the Quarkus application:

```apache
ProxyPass /acme-theme.css http://quarkus-app:8080/acme-theme.css
ProxyPassReverse /acme-theme.css http://quarkus-app:8080/acme-theme.css

<Location /acme-theme.css>
    Require all granted
</Location>
```

This ensures the CSS file is accessible without authentication.

## Theme Consistency

To maintain consistency across all pages, both the Keycloak theme CSS and Quarkus shared CSS use the same:
- CSS variable names and values for colors
- Typography settings
- Layout structure (600px max-width containers)
- Spacing and padding values
- Button styling

## Customization

### Keycloak Theme Files

- **CSS Styles**: `keycloak/themes/acme-theme/login/resources/css/custom.css`
- **FreeMarker Template**: `keycloak/themes/acme-theme/login/login.ftl`
- **Theme Configuration**: `keycloak/themes/acme-theme/login/theme.properties`

### Quarkus Theme Files

- **Shared CSS**: `quarkus-app/src/main/resources/META-INF/resources/acme-theme.css`
- **HTML Templates**: 
  - `quarkus-app/src/main/resources/user-info.html`
  - `quarkus-app/src/main/resources/logged-out.html`

### Making Changes

1. **Keycloak Theme**: Edit the CSS or FreeMarker template files, then restart Keycloak (or rebuild the Docker image if the theme is built in)
2. **Quarkus Theme**: Edit the CSS or HTML template files, then rebuild the Quarkus application

## Deployment

### Keycloak Theme Deployment

The Keycloak theme is currently deployed using **volume mount** in `podman-compose.yml`:

```yaml
keycloak:
  volumes:
    - ./keycloak/themes:/opt/keycloak/themes:ro
```

This allows theme changes to be applied by restarting the Keycloak container without rebuilding the image.

#### Alternative: Building Theme into Image

To build the theme into the Keycloak Docker image instead, create a `keycloak/Dockerfile`:

```dockerfile
FROM registry.redhat.io/rhbk/keycloak-rhel9:26.4
COPY themes/acme-theme /opt/keycloak/themes/acme-theme
```

Then update `podman-compose.yml` to build the image:

```yaml
keycloak:
  build:
    context: ./keycloak
    dockerfile: Dockerfile
  # Remove or comment out the themes volume mount
```

### Quarkus Theme Deployment

The Quarkus theme CSS is automatically included when the application is built. The CSS file in `META-INF/resources/` is served as a static resource.

Apache must be configured to proxy CSS requests:

```apache
ProxyPass /acme-theme.css http://quarkus-app:8080/acme-theme.css
ProxyPassReverse /acme-theme.css http://quarkus-app:8080/acme-theme.css

<Location /acme-theme.css>
    Require all granted
</Location>
```

## Troubleshooting

### Theme Not Showing in Keycloak

1. Verify `loginTheme: "acme-theme"` is set in `keycloak/realm-config.json`
2. Ensure the theme directory structure matches Keycloak's expectations
3. Check Keycloak logs for theme loading errors
4. Restart Keycloak after theme changes
5. If using volume mount, verify the mount path is correct

### CSS Not Loading

1. **Keycloak**: Ensure the CSS file path in `login/theme.properties` is correct (`styles=css/custom.css`)
2. **Quarkus**: Verify the CSS file is in `META-INF/resources/` and Apache is configured to proxy it
3. Check browser developer tools network tab for 404 errors

