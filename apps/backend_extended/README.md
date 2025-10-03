# Backend Extended

Extended backend application written in Spring Boot that shares the database with the main backend.

## Features

- User registration
- User data retrieval
- User deletion (soft delete)
- Health check endpoint

## Requirements

- **Java 21** (optional - will be automatically downloaded if not available)
- **Maven** (optional - will be automatically downloaded if not available)

## Running the Application

### 🐳 Running with Docker (RECOMMENDED - no Java/Maven installation needed)

Use the Docker scripts from the main project directory - **no local Java or Maven installation required!**

**Windows:**
```cmd
start-backend-extended-docker.bat
```

**macOS/Linux:**
```bash
./start-backend-extended-docker.sh
```

#### What Docker scripts do automatically:
- ✅ Check if Docker is installed and running
- ✅ Automatically start PostgreSQL database (if not running)
- ✅ Build Docker image with the application (Java and Maven are in the container)
- ✅ Run the application in a Docker container
- ✅ Configure database connection
- ✅ Display application logs
- ✅ **NO REQUIREMENT** for local Java 21 or Maven installation!

#### Docker Requirements:
- Docker Desktop (Windows/Mac) or Docker Engine (Linux)
- That's it! 🎉

---

### 💻 Local Deployment (with auto-installation of tools)

If you prefer to run the application directly on your system:

**Windows:**
```cmd
start-backend-extended.bat
```

**macOS/Linux:**
```bash
./start-backend-extended.sh
```

#### What local scripts do automatically:
- ✅ Check for Java 21 and Maven availability globally
- ✅ If Java 21 is not available, download and install it locally for the project
- ✅ If Maven is not available, download and install it locally for the project
- ✅ Configure environment variables only for this project (no global conflicts)
- ✅ Build and run the Spring Boot application

#### Local Tools:
Scripts install tools in the `apps/backend_extended/tools/` directory:
```
tools/
├── jdk-21/              # Local Java 21 installation
└── apache-maven-3.9.6/  # Local Maven installation
```

### Manual Deployment

If you have Java 21 and Maven installed globally:

```bash
cd apps/backend_extended
./mvnw spring-boot:run
```

The service will be available on port 8081.

## API Endpoints

### Health Check
- `GET /api/health` - check application status

### Users
- `POST /api/users/register` - register a new user
- `GET /api/users/{id}` - retrieve user data
- `DELETE /api/users/{id}` - delete a user

## Database

The application connects to the same PostgreSQL database as the main backend (`monorepo-starter`).

## Configuration

Configuration is located in `src/main/resources/application.properties`. For Docker environment, the `docker` profile is used.
