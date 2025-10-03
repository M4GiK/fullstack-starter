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

echo %BLUE% Starting Fullstack Starter Development Environment
echo.

REM Get project directory
set "PROJECT_DIR=%~dp0"
set "PROJECT_DIR=%PROJECT_DIR:~0,-1%"

REM Function to check if a port is open
:check_port
powershell -Command "& {try { $tcp = New-Object System.Net.Sockets.TcpClient; $tcp.Connect('localhost', %~1); $tcp.Close(); exit 0 } catch { exit 1 }}" >nul 2>&1
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


REM Function to start database and backend-extended
:start_database_and_backend_extended
echo %BLUE% Starting database and backend-extended services...
where docker-compose >nul 2>&1
if %errorlevel% equ 0 (
    docker-compose up -d database-postgres localstack backend-extended
) else (
    where docker >nul 2>&1
    if %errorlevel% equ 0 (
        docker compose up -d database-postgres localstack backend-extended
    ) else (
        echo %RED% Docker Compose is required but not found.
        echo Please install Docker and Docker Compose to continue.
        pause
        exit /b 1
    )
)
call :wait_for_service "PostgreSQL" "5432"
call :wait_for_service "Backend Extended" "8081"
goto :eof

REM Function to start backend
:start_backend
echo %BLUE% Starting backend (Node.js)...

where node >nul 2>&1
if %errorlevel% neq 0 (
    echo %RED% Node.js is required but not found.
    pause
    exit /b 1
)

cd "%PROJECT_DIR%\apps\backend"

if not exist "node_modules" (
    echo %BLUE% Installing backend dependencies...
    npm install
)

REM Start backend
start "Backend" npm run dev

call :wait_for_service "Backend" "3001"

cd "%PROJECT_DIR%"
goto :eof


REM Function to start frontend
:start_frontend
echo %BLUE% Starting frontend (React)...

cd "%PROJECT_DIR%\apps\frontend"

if not exist "node_modules" (
    echo %BLUE% Installing frontend dependencies...
    npm install
)

REM Start frontend
start "Frontend" npm run dev

call :wait_for_service "Frontend" "5173"

cd "%PROJECT_DIR%"
goto :eof

REM Main execution
echo.
call :start_database_and_backend_extended
echo.
call :start_backend
echo.
call :start_frontend
echo.
echo [OK] All services are running!
echo.
echo Service URLs:
echo   Frontend:     http://localhost:5173
echo   Backend:      http://localhost:3001
echo   Backend Ext:  http://localhost:8081
echo   Database:     localhost:5432
echo   LocalStack:   http://localhost:4566
echo.
echo Press Ctrl+C to stop all services
echo.

REM Wait for user interrupt
pause >nul
