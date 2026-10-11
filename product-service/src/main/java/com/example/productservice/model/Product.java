package com.example.productservice.model;

/**
 * Represents a Product entity/data transfer object.
 * Simple Plain Old Java Object (POJO) with getters and setters.
 */
public class Product {
    private Long id;
    private String name;
    private Double price;

    // Default constructor needed for JSON deserialization
    public Product() {
    }

    // Parameterized constructor to create sample products easily
    public Product(Long id, String name, Double price) {
        this.id = id;
        this.name = name;
        this.price = price;
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

    public Double getPrice() {
        return price;
    }

    public void setPrice(Double price) {
        this.price = price;
    }
}
