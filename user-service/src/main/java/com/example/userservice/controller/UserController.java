package com.example.userservice.controller;

import com.example.userservice.model.User;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.Arrays;
import java.util.List;

/**
 * REST Controller that handles incoming HTTP requests for users.
 */
@RestController
@RequestMapping("/users")
public class UserController {

    /**
     * Handles GET /users
     * Returns a JSON list of 2 sample users.
     */
    @GetMapping
    public List<User> getUsers() {
        return Arrays.asList(
            new User(1L, "Alice Johnson", "alice@example.com"),
            new User(2L, "Bob Smith", "bob@example.com")
        );
    }
}
