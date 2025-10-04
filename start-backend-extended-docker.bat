@echo off
REM Script to start backend-extended service using Docker
REM No local Java or Maven installation required!

setlocal enabledelayedexpansion

REM Get the directory where the script is located
set "SCRIPT_DIR=%~dp0"
set "PROJECT_ROOT=%SCRIPT_DIR%"
set "BACKEND_DIR=%PROJECT_ROOT%apps\backend_extended"

REM Docker image and container names
set "IMAGE_NAME=backend-extended"
set "CONTAINER_NAME=backend-extended-app"
set "NETWORK_NAME=fullstack-starter_default"

echo.
echo =========================================
echo   Backend Extended - Docker Launch
echo =========================================
echo.

REM Check if Docker is installed and running
echo Checking Docker installation...
where docker >nul 2>&1
if %errorlevel% neq 0 (
    echo [ERROR] Docker is not installed!
    echo.
    echo Please install Docker Desktop from:
    echo https://docs.docker.com/desktop/install/windows-install/
    echo.
    pause
    exit /b 1
)

docker info >nul 2>&1
if %errorlevel% neq 0 (
    echo [ERROR] Docker is not running!
    echo.
    echo Please start Docker Desktop and try again.
    pause
    exit /b 1
)

echo [OK] Docker is installed and running

REM Check Docker Compose
docker compose version >nul 2>&1
if %errorlevel% equ 0 (
    set "COMPOSE_CMD=docker compose"
    echo [OK] Docker Compose is available
) else (
    where docker-compose >nul 2>&1
    if %errorlevel% equ 0 (
        set "COMPOSE_CMD=docker-compose"
        echo [OK] Docker Compose is available
    ) else (
        echo [ERROR] Docker Compose is not available!
        pause
        exit /b 1
    )
)

REM Check if database is running
echo.
echo Checking PostgreSQL database...

docker ps --format "{{.Names}}" | findstr "monorepo-starter-postgres" >nul 2>&1
if %errorlevel% equ 0 (
    echo [OK] PostgreSQL database is already running
) else (
    echo [WARNING] PostgreSQL database is not running
    echo Starting database with docker-compose...
    
    cd /d "%PROJECT_ROOT%"
    %COMPOSE_CMD% up -d database-postgres
    
    echo Waiting for database to be ready...
    timeout /t 5 /nobreak >nul
    
    REM Wait for postgres to be ready
    set "MAX_TRIES=30"
    set "TRIES=0"
    
    :wait_db
    docker exec monorepo-starter-postgres pg_isready -U postgres >nul 2>&1
    if %errorlevel% equ 0 (
        echo [OK] Database is ready!
        goto :db_ready
    )
    
    set /a TRIES+=1
    if !TRIES! geq !MAX_TRIES! (
        echo [ERROR] Database failed to start
        pause
        exit /b 1
    )
    
    echo Waiting for database... (!TRIES!/!MAX_TRIES!)
    timeout /t 1 /nobreak >nul
    goto :wait_db
)

:db_ready

REM Build Docker image
echo.
echo =========================================
echo   Building Docker image...
echo =========================================

cd /d "%BACKEND_DIR%"

docker build -t "%IMAGE_NAME%:latest" .

if %errorlevel% neq 0 (
    echo [ERROR] Failed to build Docker image
    pause
    exit /b 1
)

echo [OK] Docker image built successfully!

REM Stop existing container if running
docker ps -a --format "{{.Names}}" | findstr "^%CONTAINER_NAME%$" >nul 2>&1
if %errorlevel% equ 0 (
    echo.
    echo Stopping and removing existing container...
    docker stop "%CONTAINER_NAME%" >nul 2>&1
    docker rm "%CONTAINER_NAME%" >nul 2>&1
    echo [OK] Existing container removed
)

REM Run Docker container
echo.
echo =========================================
echo   Starting Backend Extended container...
echo =========================================

REM Determine database host
set "DB_HOST=host.docker.internal"

REM Check if docker-compose network exists
docker network ls | findstr "%NETWORK_NAME%" >nul 2>&1
if %errorlevel% equ 0 (
    set "NETWORK_OPTION=--network %NETWORK_NAME%"
    set "DB_HOST=database-postgres"
) else (
    set "NETWORK_OPTION="
)

docker run -d ^
    --name "%CONTAINER_NAME%" ^
    -p 8081:8081 ^
    -e "SPRING_DATASOURCE_URL=jdbc:postgresql://%DB_HOST%:5432/monorepo-starter" ^
    -e "SPRING_DATASOURCE_USERNAME=postgres" ^
    -e "SPRING_DATASOURCE_PASSWORD=postgres" ^
    -e "SPRING_JPA_HIBERNATE_DDL_AUTO=validate" ^
    %NETWORK_OPTION% ^
    "%IMAGE_NAME%:latest"

if %errorlevel% neq 0 (
    echo [ERROR] Failed to start container
    pause
    exit /b 1
)

echo [OK] Container started successfully!
echo.
echo =========================================
echo   Backend Extended is now running!
echo =========================================
echo.
echo Service URL:      http://localhost:8081
echo Health Check:     http://localhost:8081/api/health
echo.
echo Useful commands:
echo   View logs:          docker logs -f %CONTAINER_NAME%
echo   Stop container:     docker stop %CONTAINER_NAME%
echo   Remove container:   docker rm %CONTAINER_NAME%
echo   Restart container:  docker restart %CONTAINER_NAME%
echo.
echo Showing startup logs (Ctrl+C to exit, container will keep running)...
echo =========================================
docker logs -f "%CONTAINER_NAME%"

pause
