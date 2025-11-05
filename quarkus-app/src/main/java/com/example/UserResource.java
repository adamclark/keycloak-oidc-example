package com.example;

import jakarta.ws.rs.GET;
import jakarta.ws.rs.Path;
import jakarta.ws.rs.core.HttpHeaders;
import jakarta.ws.rs.core.Response;

@Path("/user")
public class UserResource {

    @GET
    public Response getUserInfo(@jakarta.ws.rs.core.Context HttpHeaders headers) {
        String userId = headers.getHeaderString("X-User-Id");
        
        if (userId == null || userId.isEmpty()) {
            return Response.status(Response.Status.BAD_REQUEST)
                .entity("{\"error\": \"User ID header (X-User-Id) not found\"}")
                .build();
        }
        
        String response = String.format("{\"user_id\": \"%s\"}", userId);
        return Response.ok(response)
            .type("application/json")
            .build();
    }
}

