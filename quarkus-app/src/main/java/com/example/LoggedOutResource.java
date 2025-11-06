package com.example;

import jakarta.ws.rs.GET;
import jakarta.ws.rs.Path;
import jakarta.ws.rs.core.Response;

@Path("/logged-out")
public class LoggedOutResource {

    private static final String LOGGED_OUT_TEMPLATE = TemplateUtil.loadTemplate("/logged-out.html");

    @GET
    public Response getLoggedOutPage() {
        // Replace placeholders in logged-out template
        String html = LOGGED_OUT_TEMPLATE
            .replace("{LOGIN_URL}", "/user");
        
        return Response.ok(html)
            .type("text/html")
            .build();
    }
}