# ==========================================
# Stage 1: Build the application using Maven
# ==========================================
FROM maven:3.9-eclipse-temurin-25 AS build

WORKDIR /app

# Copy Maven descriptor and source code
COPY pom.xml .
COPY src ./src

# Build the Spring Boot application (skipping tests for faster build)
RUN mvn clean package -DskipTests

# ==========================================
# Stage 2: Run the application using JRE
# ==========================================
FROM eclipse-temurin:25-jre

WORKDIR /app

# Copy the generated JAR file from the build stage as app.jar
COPY --from=build /app/target/*.jar app.jar

# Expose port 8082 for the product-service
EXPOSE 8082

# Command to run the application
ENTRYPOINT ["java", "-jar", "app.jar"]
