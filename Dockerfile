# Stage 1: Build
FROM maven:3.9.6-eclipse-temurin-17 AS build
WORKDIR /app

# [CRITICAL FIX] 
# Explicitly copy the 'backend-java' folder contents to the current directory (/app)
# This handles the case where Render's Root Directory is set to the repo root.
COPY backend-java/ .

# Now the pom.xml should be in /app/pom.xml
RUN mvn clean package -DskipTests

# Stage 2: Run
FROM eclipse-temurin:17-jre-jammy
WORKDIR /app
# The jar will be in /app/target because we built it in /app
COPY --from=build /app/target/*.jar app.jar
EXPOSE 8080
ENTRYPOINT ["java","-jar","app.jar"]
