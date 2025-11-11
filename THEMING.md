# Theme Customization Guide

This document explains how the ACME Company theme is configured and deployed across the application.

## Overview

The application uses a consistent ACME Company theme across the main pages:
1. **User Info Page** - Quarkus application page showing user information
2. **Logged Out Page** - Quarkus application page shown after logout

All pages share the same color scheme, typography, and styling to provide a cohesive user experience.

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

## Customization

### Quarkus Theme Files

- **Shared CSS**: `quarkus-app/src/main/resources/META-INF/resources/acme-theme.css`
- **HTML Templates**: 
  - `quarkus-app/src/main/resources/user-info.html`
  - `quarkus-app/src/main/resources/logged-out.html`

### Making Changes

1. **Quarkus Theme**: Edit the CSS or HTML template files, then rebuild the Quarkus application

## Deployment

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

### CSS Not Loading

1. **Quarkus**: Verify the CSS file is in `META-INF/resources/` and Apache is configured to proxy it
2. Check browser developer tools network tab for 404 errors