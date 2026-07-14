# ---------- Stage 1: Build ----------
FROM maven:3.9-eclipse-temurin-17 AS build
WORKDIR /app

# Copy pom.xml first to leverage Docker layer caching for dependencies
COPY pom.xml .
RUN mvn -B dependency:go-offline

# Copy source and build the jar (skip tests here; Jenkins runs them in the Test stage)
COPY src ./src
RUN mvn -B clean package -DskipTests

# ---------- Stage 2: Run ----------
FROM eclipse-temurin:17-jre-jammy
WORKDIR /app

# Run as non-root user for better container security
RUN groupadd -r ottapp && useradd -r -g ottapp ottapp

COPY --from=build /app/target/ott-platform.jar app.jar

RUN chown -R ottapp:ottapp /app
USER ottapp

EXPOSE 8080

HEALTHCHECK --interval=30s --timeout=5s --start-period=30s --retries=3 \
    CMD wget -qO- http://localhost:8080/api/ping || exit 1

ENTRYPOINT ["java", "-jar", "app.jar"]
