# ==========================================
# Stage 1: Build the application using Maven
# ==========================================
FROM maven:3.9-eclipse-temurin-25 AS build

# Set working directory inside the container
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

# Set working directory inside the runtime container
WORKDIR /app

# Copy the generated JAR file from the build stage
COPY --from=build /app/target/*.jar app.jar

# Expose port 8081 for the microservice
EXPOSE 8081

# Command to run the application
ENTRYPOINT ["java", "-jar", "app.jar"]
