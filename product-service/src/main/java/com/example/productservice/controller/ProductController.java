package com.example.productservice.controller;

import com.example.productservice.model.Product;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.Arrays;
import java.util.List;

/**
 * REST Controller that handles incoming HTTP requests for products.
 */
@RestController
@RequestMapping("/products")
public class ProductController {

    /**
     * Handles GET /products
     * Returns a JSON list of 2 sample products.
     */
    @GetMapping
    public List<Product> getProducts() {
        return Arrays.asList(
            new Product(101L, "Laptop", 899.99),
            new Product(102L, "Wireless Mouse", 29.99)
        );
    }
}
