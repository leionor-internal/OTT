# ---------- Stage 1 : Build ----------
FROM maven:3.9.9-eclipse-temurin-17 AS builder

WORKDIR /app

COPY pom.xml .

RUN mvn -B dependency:go-offline

COPY . .

RUN mvn -B clean package -DskipTests

# ---------- Stage 2 : Runtime ----------
FROM eclipse-temurin:17-jre-jammy

WORKDIR /app

RUN groupadd -r ottapp && useradd -r -g ottapp ottapp

COPY --from=builder /app/target/ott-platform.jar app.jar

RUN chown ottapp:ottapp app.jar

USER ottapp

EXPOSE 8085

HEALTHCHECK --interval=30s --timeout=5s --start-period=30s --retries=3 \
CMD wget -qO- http://localhost:8085/api/ping || exit 1

ENTRYPOINT ["java","-jar","app.jar"]
