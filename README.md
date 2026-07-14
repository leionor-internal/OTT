# OTT Platform (DevOps Training Project)

A small Spring Boot REST API modeled on an OTT/streaming service (think mini-Netflix
backend). It's intentionally simple so students can focus on the **DevOps pipeline**
— Maven build → Docker image → docker-compose → Jenkins CI/CD — rather than the
application logic itself.

## What it does

- **Users** — sign up, manage their subscription plan (FREE / BASIC / PREMIUM)
- **Movies** — a catalog of titles, each gated behind a required plan
- **Subscriptions** — create/cancel a subscription for a user

It's a standard layered Spring Boot app: `Controller -> Service -> Repository -> Entity`,
backed by MySQL (with an H2 in-memory option for quick local runs and tests).

## Tech stack

- Java 17
- Spring Boot 3.2 (Web, Data JPA, Validation, Actuator)
- MySQL 8 (runtime) / H2 (local & test profile)
- Maven

## Project structure

```
ott-platform/
├── pom.xml
├── Dockerfile
├── docker-compose.yml
├── Jenkinsfile
├── .dockerignore
├── .gitignore
└── src/
    ├── main/java/com/training/ott/
    │   ├── OttPlatformApplication.java
    │   ├── model/          (User, Movie, Subscription)
    │   ├── repository/     (Spring Data JPA repositories)
    │   ├── service/        (business logic)
    │   ├── controller/     (REST endpoints)
    │   ├── config/         (DataSeeder — loads sample movies/users on startup)
    │   └── exception/      (custom exception + global handler)
    ├── main/resources/
    │   ├── application.properties        (MySQL config, env-var driven)
    │   └── application-local.properties  (H2 profile for local dev)
    └── test/java/com/training/ott/
        └── OttPlatformApplicationTests.java
```

## REST API quick reference

| Method | Endpoint                         | Description                      |
|--------|-----------------------------------|-----------------------------------|
| GET    | /api/ping                        | Quick health check                |
| GET    | /api/users                       | List users                        |
| POST   | /api/users                       | Create user                       |
| GET    | /api/movies                      | List movies                       |
| GET    | /api/movies/genre/{genre}        | Filter movies by genre            |
| POST   | /api/movies                      | Add a movie                       |
| POST   | /api/subscriptions                | Create a subscription (see body below) |
| GET    | /api/subscriptions/user/{userId} | List a user's subscriptions       |
| DELETE | /api/subscriptions/{id}          | Cancel a subscription             |
| GET    | /actuator/health                 | Spring Actuator health endpoint   |

Sample POST body for `/api/subscriptions`:
```json
{ "userId": 1, "plan": "PREMIUM", "durationInDays": 30 }
```

## Step 1 — Build with Maven

Run locally with H2 (no MySQL needed) to sanity-check the build:

```bash
mvn clean package
SPRING_PROFILES_ACTIVE=local java -jar target/ott-platform.jar
```

Then visit `http://localhost:8080/api/ping` and `http://localhost:8080/api/movies`.

## Step 2 — Dockerize

The included `Dockerfile` is a multi-stage build (Maven build stage + slim JRE
runtime stage, running as a non-root user):

```bash
docker build -t ott-platform:latest .
docker run -p 8080:8080 --env SPRING_PROFILES_ACTIVE=local ott-platform:latest
```

## Step 3 — docker-compose (app + MySQL)

```bash
docker compose up -d --build
```

This spins up a MySQL container and the app container on a shared network, wired
together via environment variables (`DB_HOST`, `DB_USERNAME`, etc. — see
`application.properties`). Tear down with `docker compose down -v`.

## Step 4 — Jenkins pipeline

The `Jenkinsfile` defines a declarative pipeline:

1. **Checkout** — pull source from SCM
2. **Build** — `mvn compile`
3. **Test** — `mvn test` (publishes JUnit results)
4. **Package** — `mvn package`, archives the jar
5. **Docker Build** — builds the image, tagged with `${BUILD_NUMBER}` and `latest`
6. **Docker Push** — pushes to a registry (Docker Hub by default)
7. **Deploy** — `docker compose up -d --build`

Before running this in Jenkins, students will need to:
- Install the **Docker Pipeline** and **Maven Integration** Jenkins plugins
- Configure a Maven tool named `Maven3` and a JDK named `JDK17` under *Manage Jenkins > Tools*
- Add a **Username/Password** credential with ID `dockerhub-credentials` for the registry login
- Replace `yourdockerhubusername/ott-platform` in the `Jenkinsfile` with their own registry path
- Make sure the Jenkins agent has Docker installed and the `jenkins` user can run `docker` commands

## Suggested exercises for students

- Add a `Dockerfile` HEALTHCHECK failure scenario and observe how docker-compose reacts
- Add a new entity (e.g. `Review`) end-to-end and extend the pipeline's test stage
- Add a SonarQube stage to the Jenkinsfile for static analysis
- Push images to a private registry instead of Docker Hub
- Convert `docker-compose.yml` into Kubernetes manifests as a follow-on exercise
