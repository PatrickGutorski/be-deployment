# -----------------------------------------------------------------------------
# STAGE 1: Build the application
# -----------------------------------------------------------------------------
# Use an official OpenJDK image with the JDK (change '17' to your Java version)
FROM eclipse-temurin:17-jdk-jammy AS builder

# Set the working directory inside the container
WORKDIR /app

# Copy the Gradle wrapper and settings files first
# This allows Docker to cache dependencies if these files haven't changed
COPY gradle/ gradle/
COPY gradlew build.gradle settings.gradle ./

# Grant execution permission to the Gradle wrapper
RUN chmod +x gradlew

# Download dependencies (this step is cached if dependencies don't change)
RUN ./gradlew dependencies --no-daemon || return 0

# Copy the actual source code
COPY src ./src

# Build the application (skip tests to speed up the build, strictly for the image)
RUN ./gradlew bootJar --no-daemon

# -----------------------------------------------------------------------------
# STAGE 2: Create the final run image
# -----------------------------------------------------------------------------
# Use a smaller JRE image for production (no compiler, smaller size)
FROM eclipse-temurin:17-jre-jammy

WORKDIR /app

# Copy only the compiled JAR from the builder stage
# The jar is usually found in build/libs/
COPY --from=builder /app/build/libs/*.jar app.jar

# Expose the port your app runs on (default Spring Boot is 8080)
EXPOSE 8080

# The command to run the application
ENTRYPOINT ["java", "-jar", "app.jar"]