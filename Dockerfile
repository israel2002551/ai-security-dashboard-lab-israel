# --- Build Stage ---
# Use Maven to compile the Java code
FROM maven:3.8.5-openjdk-17 AS build
WORKDIR /app
COPY . .
# Package the app (skip tests to speed up deployment)
RUN mvn clean package -DskipTests

# --- Run Stage ---
# Use a lightweight Java runtime to run the app
FROM openjdk:17-jdk-slim
WORKDIR /app
# Copy the built JAR file from the build stage
COPY --from=build /app/target/*.jar app.jar
# Tell Render which port we are listening on
EXPOSE 8080
# The command to start the app
ENTRYPOINT ["java","-jar","app.jar"]
