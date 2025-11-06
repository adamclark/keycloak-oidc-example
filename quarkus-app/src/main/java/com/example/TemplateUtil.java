package com.example;

import java.io.IOException;
import java.io.InputStream;
import java.nio.charset.StandardCharsets;

public class TemplateUtil {
    
    public static String loadTemplate(String resourcePath) {
        try (InputStream is = TemplateUtil.class.getResourceAsStream(resourcePath)) {
            if (is == null) {
                throw new RuntimeException("Template file " + resourcePath + " not found in resources");
            }
            return new String(is.readAllBytes(), StandardCharsets.UTF_8);
        } catch (IOException e) {
            throw new RuntimeException("Failed to load HTML template: " + resourcePath, e);
        }
    }
}