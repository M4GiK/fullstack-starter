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
set "TOOLS_DIR=%PROJECT_DIR%\tools"
set "JAVA_DIR=%TOOLS_DIR%\java21"
set "MAVEN_DIR=%TOOLS_DIR%\maven"

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

REM Function to setup Java locally
:setup_java
echo %BLUE% Setting up Java 21 locally for backend-extended...

if not exist "%JAVA_DIR%" (
    echo Downloading Java 21...

    if not exist "%TOOLS_DIR%" mkdir "%TOOLS_DIR%"

    REM Download Java 21 for Windows x64
    powershell -Command "& {Invoke-WebRequest -Uri 'https://api.adoptium.net/v3/binary/latest/21/ga/windows/x64/jdk/hotspot/normal/eclipse' -OutFile '%TOOLS_DIR%\java21.zip'}"

    if !errorlevel! neq 0 (
        echo %RED% Failed to download Java 21.
        echo Please install Java 21 manually from https://adoptium.net/
        pause
        exit /b 1
    )

    echo Extracting Java 21...
    powershell -Command "& {Expand-Archive -Path '%TOOLS_DIR%\java21.zip' -DestinationPath '%TOOLS_DIR%'}"

    REM Find the extracted directory
    for /d %%i in ("%TOOLS_DIR%\jdk*") do (
        if exist "%%i\bin\java.exe" (
            move "%%i" "%JAVA_DIR%" >nul 2>&1
            goto :java_extracted
        )
    )

    echo %RED% Failed to extract Java 21.
    pause
    exit /b 1

    :java_extracted
    del "%TOOLS_DIR%\java21.zip"
)

set "JAVA_HOME=%JAVA_DIR%"
set "PATH=%JAVA_HOME%\bin;%PATH%"
echo Java 21 setup completed.
goto :eof

REM Function to setup Maven locally
:setup_maven
echo %BLUE% Setting up Maven locally for backend-extended...

if not exist "%MAVEN_DIR%" (
    echo Downloading Maven...

    REM Download Maven
    powershell -Command "& {Invoke-WebRequest -Uri 'https://downloads.apache.org/maven/maven-3/3.9.6/binaries/apache-maven-3.9.6-bin.zip' -OutFile '%TOOLS_DIR%\maven.zip'}"

    if !errorlevel! neq 0 (
        echo %RED% Failed to download Maven.
        echo Please install Maven manually from https://maven.apache.org/
        pause
        exit /b 1
    )

    echo Extracting Maven...
    powershell -Command "& {Expand-Archive -Path '%TOOLS_DIR%\maven.zip' -DestinationPath '%TOOLS_DIR%'}"

    REM Find the extracted directory
    for /d %%i in ("%TOOLS_DIR%\apache-maven*") do (
        if exist "%%i\bin\mvn.cmd" (
            move "%%i" "%MAVEN_DIR%" >nul 2>&1
            goto :maven_extracted
        )
    )

    echo %RED% Failed to extract Maven.
    pause
    exit /b 1

    :maven_extracted
    del "%TOOLS_DIR%\maven.zip"
)

set "PATH=%MAVEN_DIR%\bin;%PATH%"
set "MAVEN_OPTS=-Xmx1024m -XX:MaxMetaspaceSize=256m"
echo Maven setup completed.
goto :eof

REM Function to start database
:start_database
echo %BLUE% Starting database services...
where docker-compose >nul 2>&1
if %errorlevel% equ 0 (
    docker-compose up -d database-postgres localstack
) else (
    where docker >nul 2>&1
    if %errorlevel% equ 0 (
        docker compose up -d database-postgres localstack
    ) else (
        echo %RED% Docker Compose is required but not found.
        echo Please install Docker and Docker Compose to continue.
        pause
        exit /b 1
    )
)
call :wait_for_service "PostgreSQL" "5432"
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

REM Function to start backend-extended
:start_backend_extended
echo %BLUE% Starting backend-extended (Java)...

REM Check if Java 21 is available globally
java -version 2>&1 | findstr /C:"21" >nul
if %errorlevel% equ 0 (
    echo %BLUE% Using globally installed Java 21
) else (
    echo %BLUE% Java 21 not found globally, setting up local Java...
    call :setup_java
)

REM Check if Maven is available globally
mvn -version >nul 2>&1
if %errorlevel% neq 0 (
    echo %BLUE% Maven not found globally, setting up local Maven...
    call :setup_maven
)

cd "%PROJECT_DIR%\apps\backend_extended"

REM Start backend-extended
start "Backend Extended" mvnw.cmd spring-boot:run

call :wait_for_service "Backend Extended" "8081"

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
call :start_database
echo.
call :start_backend
echo.
call :start_backend_extended
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
