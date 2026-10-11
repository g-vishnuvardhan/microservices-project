package com.example.userservice.model;

/**
 * Represents a User entity/data transfer object.
 * Simple Plain Old Java Object (POJO) with getters and setters.
 */
public class User {
    private Long id;
    private String name;
    private String email;

    // Default constructor needed for JSON deserialization
    public User() {
    }

    // Parameterized constructor to create sample users easily
    public User(Long id, String name, String email) {
        this.id = id;
        this.name = name;
        this.email = email;
    }

    // Getters and Setters
    public Long getId() {
        return id;
    }

    public void setId(Long id) {
        this.id = id;
    }

    public String getName() {
        return name;
    }

    public void setName(String name) {
        this.name = name;
    }

    public String getEmail() {
        return email;
    }

    public void setEmail(String email) {
        this.email = email;
    }
}
