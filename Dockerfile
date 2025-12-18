# Stage 1: Build
FROM maven:3.9.6-eclipse-temurin-17 AS build
WORKDIR /app

# Copy the specific folder contents (Adjusting for directory structure)
# We copy everything, then move into the backend-java folder if it exists
COPY . .
RUN if [ -d "backend-java" ]; then mv backend-java/* .; fi

# Now run the build
RUN mvn clean package -DskipTests

# Stage 2: Run
FROM eclipse-temurin:17-jre-jammy
WORKDIR /app
COPY --from=build /app/target/*.jar app.jar
EXPOSE 8080
ENTRYPOINT ["java","-jar","app.jar"]
