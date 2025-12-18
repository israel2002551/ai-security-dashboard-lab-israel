# --- Build Stage ---
# Use a maintained Maven image with Eclipse Temurin Java 17
FROM maven:3.9.6-eclipse-temurin-17 AS build
WORKDIR /app
COPY . .
# Package the app
RUN mvn clean package -DskipTests

# --- Run Stage ---
# Use the maintained Eclipse Temurin runtime (Small & Secure)
FROM eclipse-temurin:17-jre-jammy
WORKDIR /app
# Copy the built JAR file from the build stage
COPY --from=build /app/target/*.jar app.jar
# Tell Render which port we are listening on
EXPOSE 8080
# The command to start the app
ENTRYPOINT ["java","-jar","app.jar"]
