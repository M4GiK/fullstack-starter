# Fullstack Starter

## Features

- **Backend**: Node.js with Fastify, Drizzle ORM, JWT authentication, and RESTful API.
- **Backend Extended**: Java Spring Boot application with JPA, PostgreSQL, and RESTful API.
- **Frontend**: React with Vite, TypeScript, and Tailwind CSS.
- **Database**: PostgreSQL with Drizzle ORM for type-safe database interactions.
- **Containerization**: Docker and Docker Compose for easy setup and deployment.
- **CI/CD**: GitHub Actions for continuous integration and deployment to Fly.io.
- **Monorepo Management**: Using Turborepo for efficient monorepo management.
- **Testing**: Vitest for automated testing for backend and frontend.
- **User module**: Basic pages for login and sign up integrated with backend.

## Getting Started

### 🚀 Quick Start (Recommended)

Start the entire development environment with a single command:

**Windows:**
```cmd
start-fullstack.bat
```

**macOS/Linux:**
```bash
./start-fullstack.sh
```

This will automatically:
- ✅ Start PostgreSQL database and LocalStack
- ✅ Install and start Backend (Node.js)
- ✅ Install Java 21 & Maven if needed, then start Backend Extended (Java)
- ✅ Install and start Frontend (React)
- ✅ Wait for all services to be ready
- ✅ Display service URLs

### Prerequisites

- [Docker](https://www.docker.com/get-started)
- [Docker Compose](https://docs.docker.com/compose/install/)
- [Node.js](https://nodejs.org/) (for local development)
- [npm](https://www.npmjs.com/) (comes with Node.js)

### Installation

1. Install dependencies:

   ```bash
   npm install
   ```

2. Build apps:

   ```bash
   npm run build
   ```

3. Lint code:

   ```bash
   npm run lint
   ```

4. Start services with Docker Compose:

   ```bash
   docker compose up -d
   ```

5. Run tests

    ```bash
    npm run test
    ```

6. Run database migrations (if you ran tests before, you can skip this step because the test setup already runs migrations):

   ```bash
   cd apps/backend
   export DATABASE_URL=postgres://postgres:postgres@localhost:5432/monorepo-starter
   npm run db:push
   ```

7. Start frontend app (in a new terminal):

   ```bash
   cd apps/frontend
   npm run dev
   ```

8. Start backend app (in a new terminal):

   ```bash
   cd apps/backend
   npm run dev
   ```

#### OPTIONAL

9. Start backend extended app (in a new terminal):

   **Option A: Docker (RECOMMENDED - no Java/Maven needed):**
   
   **Windows:**
   ```cmd
   start-backend-extended-docker.bat
   ```

   **macOS/Linux:**
   ```bash
   ./start-backend-extended-docker.sh
   ```

   *Docker scripts handle everything - no local Java or Maven installation required!*

   **Option B: Local installation (with auto-download):**
   
   **Windows:**
   ```cmd
   start-backend-extended.bat
   ```

   **macOS/Linux:**
   ```bash
   ./start-backend-extended.sh
   ```

   *Scripts automatically download and install Java 21 and Maven locally if not available globally.*

   **Option C: Manual (requires Java 21 and Maven):**
   ```bash
   cd apps/backend_extended
   ./mvnw spring-boot:run
   ```

### 🛑 Stopping Services

**Quick Start scripts** automatically handle stopping all services when you press `Ctrl+C`.

For manual stopping:
```bash
# Stop Docker services
docker-compose down

# Kill Node.js processes (find PIDs and kill manually)
# Kill Java processes (find PIDs and kill manually)
```

### 📊 Service URLs

When all services are running, you'll have access to:

- 🌐 **Frontend**: http://localhost:5173
- 🔧 **Backend (Node.js)**: http://localhost:3001
- ⚡ **Backend Extended (Java)**: http://localhost:8081
- 🗄️ **Database (PostgreSQL)**: localhost:5432
- ☁️ **LocalStack (AWS)**: http://localhost:4566
