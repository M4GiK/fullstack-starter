@echo off
REM Fullstack Starter - Complete Development Environment Launcher
REM Compatible with Windows
REM Starts: Database, Backend (Node.js), Backend Extended (Java), Frontend

setlocal enabledelayedexpansion

REM Colors for Windows (limited support)
set "GREEN=[OK]"
set "RED=[ERROR]"
set "YELLOW=[WARNING]"
set "BLUE=[INFO]"

:log_info
echo %BLUE% %~1
goto :eof

:log_success
echo %GREEN% %~1
goto :eof

:log_warning
echo %YELLOW% %~1
goto :eof

:log_error
echo %RED% %~1
goto :eof

REM Function to check system resources
:check_system_resources
call :log_info "Checking system resources..."
for /f "tokens=3" %%a in ('powershell -command "Get-WmiObject -Class Win32_LogicalDisk -Filter 'DeviceID=\"C:\"' | Select-Object -ExpandProperty FreeSpace"') do set FREE_SPACE=%%a
set /a FREE_SPACE_GB=FREE_SPACE/1073741824
if %FREE_SPACE_GB% lss 5 (
    call :log_error "Insufficient disk space!"
    call :log_info "Required: 5GB free space"
    call :log_info "Available: %FREE_SPACE_GB%GB"
    echo.
    call :log_info "Please free up some disk space and try again."
    pause
    exit /b 1
)
call :log_success "Sufficient disk space available (%FREE_SPACE_GB%GB)"
goto :eof

REM Function to check if Docker is running
:check_docker
call :log_info "Checking Docker status..."
docker info >nul 2>&1
if errorlevel 1 (
    call :log_error "Docker is not running!"
    call :log_info "Please start Docker Desktop and try again."
    pause
    exit /b 1
)
call :log_success "Docker is running"
goto :eof

call :log_info "Starting Fullstack Starter Development Environment"
echo.

REM Get project directory
set "PROJECT_DIR=%~dp0"
set "PROJECT_DIR=%PROJECT_DIR:~0,-1%"

REM Function to check if a port is open
:check_port
powershell -Command "& {try { $tcp = New-Object System.Net.Sockets.TcpClient; $tcp.Connect('localhost', %~1); $tcp.Close(); exit 0 } catch { exit 1 }}" >nul 2>&1
goto :eof

REM Function to check port availability and show warning if occupied
:check_port_availability
set "service=%~1"
set "port=%~2"
call :log_info "Checking port availability for %service% (port %port%)..."
call :check_port %port%
if %errorlevel% equ 0 (
    call :log_warning "Port %port% is already in use by %service%"
    call :log_info "This might be from a previous run. The script will attempt to reuse existing services."
    exit /b 1
) else (
    call :log_success "Port %port% is available"
    exit /b 0
)
goto :eof

REM Function to wait for service
:wait_for_service
set "service_name=%~1"
set "port=%~2"
set "max_attempts=30"
set /a "attempt=1"

echo %BLUE% Waiting for %service_name% to be ready on localhost:%port%...

:wait_loop
call :check_port %port%
if %errorlevel% equ 0 (
    echo [OK] %service_name% is ready!
    goto :eof
)

if %attempt% equ %max_attempts% (
    echo %RED% %service_name% failed to start within expected time
    goto :eof
)

echo %BLUE% Attempt %attempt%/%max_attempts% - %service_name% not ready yet...
timeout /t 2 /nobreak >nul
set /a "attempt+=1"
goto wait_loop


REM Function to check if backend-extended is already running and healthy
:check_backend_extended_status
call :log_info "Checking backend-extended service status..."
docker ps --format "{{.Names}}" | findstr "monorepo-starter-backend-extended" >nul 2>&1
if %errorlevel% equ 0 (
    call :log_success "Backend-extended container is running"
    curl -s --max-time 5 http://localhost:8081/api/health >nul 2>&1
    if %errorlevel% equ 0 (
        call :log_success "Backend-extended API is responding"
        exit /b 0
    ) else (
        call :log_warning "Backend-extended container running but API not responding"
        call :log_info "Will restart the service..."
        exit /b 1
    )
) else (
    call :log_info "Backend-extended is not running"
    exit /b 1
)
goto :eof

REM Function to start database and backend-extended
:start_database_and_backend_extended
call :log_info "Starting database and backend-extended services..."

call :check_backend_extended_status
if %errorlevel% equ 0 (
    call :log_success "Using existing backend-extended service"
) else (
    call :log_info "Starting fresh backend-extended service..."
)

where docker-compose >nul 2>&1
if %errorlevel% equ 0 (
    docker-compose up -d database-postgres localstack backend-extended
) else (
    where docker >nul 2>&1
    if %errorlevel% equ 0 (
        docker compose up -d database-postgres localstack backend-extended
    ) else (
        call :log_error "Docker Compose is required but not found."
        call :log_info "Please install Docker and Docker Compose to continue."
        pause
        exit /b 1
    )
)

call :wait_for_service "PostgreSQL" "5432"
call :wait_for_service "Backend Extended" "8081"

call :log_info "Verifying backend-extended API endpoints..."
curl -s --max-time 10 http://localhost:8081/api/health >nul 2>&1
if %errorlevel% equ 0 (
    call :log_success "Backend-extended API is accessible"
) else (
    call :log_warning "Backend-extended API check failed, but service might still be starting..."
)
goto :eof

REM Function to check if backend (Node.js) is already running
:check_backend_status
call :log_info "Checking backend (Node.js) service status..."
call :check_port 3001
if %errorlevel% equ 0 (
    call :log_success "Backend (Node.js) appears to be running on port 3001"
    curl -s --max-time 5 http://localhost:3001/api/health >nul 2>&1
    if %errorlevel% equ 0 (
        call :log_success "Backend API is responding"
        exit /b 0
    ) else (
        call :log_warning "Backend port occupied but API not responding"
        exit /b 1
    )
) else (
    call :log_info "Backend (Node.js) is not running"
    exit /b 1
)
goto :eof

REM Function to start backend
:start_backend
call :log_info "Starting backend (Node.js)..."

call :check_backend_status
if %errorlevel% equ 0 (
    call :log_success "Using existing backend (Node.js) service"
    goto :eof
)

where node >nul 2>&1
if %errorlevel% neq 0 (
    call :log_error "Node.js is required but not found."
    call :log_info "Please install Node.js (version 16+) to continue."
    pause
    exit /b 1
)

for /f "tokens=*" %%i in ('node -v') do set NODE_VER=%%i
call :log_success "Node.js version: %NODE_VER%"

cd "%PROJECT_DIR%\apps\backend"

if not exist "node_modules" (
    call :log_info "Installing backend dependencies..."
    call :log_info "This may take a few minutes..."
    npm install
    if errorlevel 1 (
        call :log_error "Failed to install backend dependencies"
        cd "%PROJECT_DIR%"
        exit /b 1
    )
    call :log_success "Dependencies installed"
) else (
    call :log_info "Backend dependencies already installed"
)

call :log_info "Starting backend development server..."
start /b npm run dev

call :log_info "Waiting for backend to be ready..."
timeout /t 10 /nobreak >nul 2>&1

curl -s --max-time 5 http://localhost:3001/api/health >nul 2>&1
if %errorlevel% equ 0 (
    call :log_success "Backend started successfully"
) else (
    call :log_error "Backend failed to start properly"
    cd "%PROJECT_DIR%"
    exit /b 1
)

cd "%PROJECT_DIR%"
goto :eof


REM Function to check if frontend (React) is already running
:check_frontend_status
call :log_info "Checking frontend (React) service status..."
call :check_port 5173
if %errorlevel% equ 0 (
    call :log_success "Frontend (React) appears to be running on port 5173"
    curl -s --max-time 5 http://localhost:5173 >nul 2>&1
    if %errorlevel% equ 0 (
        call :log_success "Frontend dev server is responding"
        exit /b 0
    ) else (
        call :log_warning "Frontend port occupied but dev server not responding"
        exit /b 1
    )
) else (
    call :log_info "Frontend (React) is not running"
    exit /b 1
)
goto :eof

REM Function to start frontend
:start_frontend
call :log_info "Starting frontend (React)..."

call :check_frontend_status
if %errorlevel% equ 0 (
    call :log_success "Using existing frontend (React) service"
    goto :eof
)

cd "%PROJECT_DIR%\apps\frontend"

if not exist "node_modules" (
    call :log_info "Installing frontend dependencies..."
    call :log_info "This may take a few minutes..."
    npm install
    if errorlevel 1 (
        call :log_error "Failed to install frontend dependencies"
        cd "%PROJECT_DIR%"
        exit /b 1
    )
    call :log_success "Dependencies installed"
) else (
    call :log_info "Frontend dependencies already installed"
)

call :log_info "Starting frontend development server..."
start /b npm run dev

call :log_info "Waiting for frontend to be ready..."
timeout /t 10 /nobreak >nul 2>&1

curl -s --max-time 5 http://localhost:5173 >nul 2>&1
if %errorlevel% equ 0 (
    call :log_success "Frontend started successfully"
) else (
    call :log_error "Frontend failed to start properly"
    cd "%PROJECT_DIR%"
    exit /b 1
)

cd "%PROJECT_DIR%"
goto :eof

REM Function to show final status
:show_final_status
echo.
echo =========================================
call :log_success "Fullstack Development Environment Status"
echo =========================================
echo.
set "all_healthy=true"

REM Frontend
call :check_port 5173
if %errorlevel% equ 0 (
    curl -s --max-time 3 http://localhost:5173 >nul 2>&1
    if %errorlevel% equ 0 (
        call :log_success "Frontend (React):    http://localhost:5173"
    ) else (
        call :log_error "Frontend (React):    http://localhost:5173"
        set "all_healthy=false"
    )
) else (
    call :log_error "Frontend (React):    http://localhost:5173"
    set "all_healthy=false"
)

REM Backend (Node.js)
call :check_port 3001
if %errorlevel% equ 0 (
    curl -s --max-time 3 http://localhost:3001/api/health >nul 2>&1
    if %errorlevel% equ 0 (
        call :log_success "Backend (Node.js):   http://localhost:3001"
    ) else (
        call :log_error "Backend (Node.js):   http://localhost:3001"
        set "all_healthy=false"
    )
) else (
    call :log_error "Backend (Node.js):   http://localhost:3001"
    set "all_healthy=false"
)

REM Backend Extended (Java)
docker ps --format "{{.Names}}" | findstr "monorepo-starter-backend-extended" >nul 2>&1
if %errorlevel% equ 0 (
    curl -s --max-time 3 http://localhost:8081/api/health >nul 2>&1
    if %errorlevel% equ 0 (
        call :log_success "Backend Extended:  http://localhost:8081"
    ) else (
        call :log_error "Backend Extended:  http://localhost:8081"
        set "all_healthy=false"
    )
) else (
    call :log_error "Backend Extended:  http://localhost:8081"
    set "all_healthy=false"
)

REM Database
docker ps --format "{{.Names}}" | findstr "monorepo-starter-postgres" >nul 2>&1
if %errorlevel% equ 0 (
    call :log_success "Database:          localhost:5432"
) else (
    call :log_error "Database:          localhost:5432"
    set "all_healthy=false"
)

REM LocalStack
docker ps --format "{{.Names}}" | findstr "monorepo-starter-localstack" >nul 2>&1
if %errorlevel% equ 0 (
    call :log_success "LocalStack:        http://localhost:4566"
) else (
    call :log_error "LocalStack:        http://localhost:4566"
    set "all_healthy=false"
)

echo.
if "!all_healthy!"=="true" (
    call :log_success "All services are running and healthy!"
    echo.
    call :log_info "Useful commands:"
    echo   docker-compose logs -f [service-name]
    echo   docker-compose down
    echo   %~nx0
) else (
    call :log_warning "Some services may not be fully operational"
    call :log_info "Check individual service logs for more details"
)
goto :eof

REM Main execution
call :log_info "Starting Fullstack Starter Development Environment"
echo.

REM Pre-flight checks
call :check_system_resources
call :check_docker
echo.

REM Check port availability (warnings only)
call :check_port_availability "Frontend" 5173
call :check_port_availability "Backend (Node.js)" 3001
call :check_port_availability "Backend Extended" 8081
echo.

call :start_database_and_backend_extended
echo.
call :start_backend
echo.
call :start_frontend
echo.

REM Final status check
call :show_final_status
echo.
call :log_info "Press Ctrl+C to stop all services"
echo.
call :log_info "Or run: docker-compose down"

REM Wait for user interrupt
pause >nul
