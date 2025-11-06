package com.example;

import java.net.URLEncoder;
import java.nio.charset.StandardCharsets;

import jakarta.ws.rs.GET;
import jakarta.ws.rs.Path;
import jakarta.ws.rs.core.HttpHeaders;
import jakarta.ws.rs.core.Response;

@Path("/user")
public class UserResource {

    private static final String HTML_TEMPLATE = TemplateUtil.loadTemplate("/user-info.html");

    @GET
    public Response getUserInfo(@jakarta.ws.rs.core.Context HttpHeaders headers) {
        String userId = headers.getHeaderString("X-User-Id");
        
        if (userId == null || userId.isEmpty()) {
            return Response.status(Response.Status.BAD_REQUEST)
                .entity("{\"error\": \"User ID header (X-User-Id) not found\"}")
                .build();
        }
        
        String redirectUri = URLEncoder.encode("https://localhost:8443/logged-out", StandardCharsets.UTF_8);
        String logoutUrl = "/redirect_uri?logout=" + redirectUri;

        // Replace placeholders in HTML template
        String html = HTML_TEMPLATE
            .replace("{USER_ID}", userId)
            .replace("{LOGOUT_URL}", logoutUrl);
        
        return Response.ok(html)
            .type("text/html")
            .build();
    }
}

