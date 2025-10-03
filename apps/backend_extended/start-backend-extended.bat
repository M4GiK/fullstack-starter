@echo off
REM Script to start backend-extended service with automatic tool installation
REM Compatible with Windows

setlocal enabledelayedexpansion

REM Get the directory where the script is located
set "SCRIPT_DIR=%~dp0"
set "PROJECT_ROOT=%SCRIPT_DIR%"
set "BACKEND_DIR=%PROJECT_ROOT%apps\backend_extended"
set "TOOLS_DIR=%BACKEND_DIR%\tools"

REM Required versions
set "JAVA_VERSION=21"
set "MAVEN_VERSION=3.9.6"

echo =========================================
echo Backend Extended - Auto Setup and Start
echo =========================================
echo.

REM Create tools directory if it doesn't exist
if not exist "%TOOLS_DIR%" mkdir "%TOOLS_DIR%"

REM Function to check Java
:check_java
where java >nul 2>&1
if %errorlevel% equ 0 (
    java -version 2>&1 | findstr /C:"%JAVA_VERSION%" >nul
    if %errorlevel% equ 0 (
        echo [OK] Java %JAVA_VERSION% found in PATH
        goto :check_maven_start
    )
)

REM Check in tools directory
if exist "%TOOLS_DIR%\jdk-%JAVA_VERSION%" (
    set "JAVA_HOME=%TOOLS_DIR%\jdk-%JAVA_VERSION%"
    set "PATH=!JAVA_HOME!\bin;!PATH!"
    echo [OK] Java %JAVA_VERSION% found in tools
    goto :check_maven_start
)

echo Java %JAVA_VERSION% not found. Installing...
goto :install_java

:install_java
echo.
echo Installing Java %JAVA_VERSION%...
echo This may take a few minutes...

cd /d "%TOOLS_DIR%"

REM Determine architecture
set "ARCH=x64"
if "%PROCESSOR_ARCHITECTURE%"=="ARM64" set "ARCH=aarch64"
if "%PROCESSOR_ARCHITEW6432%"=="ARM64" set "ARCH=aarch64"

REM Download URL
set "JDK_URL=https://download.oracle.com/java/21/latest/jdk-21_windows-x64_bin.zip"
set "JDK_ARCHIVE=jdk-21_windows.zip"

echo Downloading JDK from: %JDK_URL%

REM Download using PowerShell
powershell -Command "& {[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; Invoke-WebRequest -Uri '%JDK_URL%' -OutFile '%JDK_ARCHIVE%'}"

if %errorlevel% neq 0 (
    echo Error: Failed to download JDK
    pause
    exit /b 1
)

echo Extracting JDK...
powershell -Command "& {Expand-Archive -Path '%JDK_ARCHIVE%' -DestinationPath '.' -Force}"

REM Find and rename the extracted directory
for /d %%i in (jdk-*) do (
    if not "%%i"=="jdk-%JAVA_VERSION%" (
        if exist "jdk-%JAVA_VERSION%" rmdir /s /q "jdk-%JAVA_VERSION%"
        ren "%%i" "jdk-%JAVA_VERSION%"
    )
)

del /f "%JDK_ARCHIVE%"

set "JAVA_HOME=%TOOLS_DIR%\jdk-%JAVA_VERSION%"
set "PATH=%JAVA_HOME%\bin;%PATH%"

echo [OK] Java %JAVA_VERSION% installed successfully!
java -version
goto :check_maven_start

:check_maven_start
echo.
echo Checking Maven...

where mvn >nul 2>&1
if %errorlevel% equ 0 (
    echo [OK] Maven found in PATH
    goto :start_application
)

REM Check in tools directory
if exist "%TOOLS_DIR%\apache-maven-%MAVEN_VERSION%" (
    set "MAVEN_HOME=%TOOLS_DIR%\apache-maven-%MAVEN_VERSION%"
    set "PATH=!MAVEN_HOME!\bin;!PATH!"
    echo [OK] Maven found in tools
    goto :start_application
)

echo Maven not found. Installing...
goto :install_maven

:install_maven
echo.
echo Installing Maven %MAVEN_VERSION%...

cd /d "%TOOLS_DIR%"

set "MAVEN_URL=https://archive.apache.org/dist/maven/maven-3/%MAVEN_VERSION%/binaries/apache-maven-%MAVEN_VERSION%-bin.zip"
set "MAVEN_ARCHIVE=apache-maven-%MAVEN_VERSION%-bin.zip"

echo Downloading Maven from: %MAVEN_URL%

REM Download using PowerShell
powershell -Command "& {[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; Invoke-WebRequest -Uri '%MAVEN_URL%' -OutFile '%MAVEN_ARCHIVE%'}"

if %errorlevel% neq 0 (
    echo Error: Failed to download Maven
    pause
    exit /b 1
)

echo Extracting Maven...
powershell -Command "& {Expand-Archive -Path '%MAVEN_ARCHIVE%' -DestinationPath '.' -Force}"

del /f "%MAVEN_ARCHIVE%"

set "MAVEN_HOME=%TOOLS_DIR%\apache-maven-%MAVEN_VERSION%"
set "PATH=%MAVEN_HOME%\bin;%PATH%"

echo [OK] Maven installed successfully!
mvn -version
goto :start_application

:start_application
echo.
echo =========================================
echo All tools ready! Starting application...
echo =========================================
echo.

REM Navigate to backend directory
cd /d "%BACKEND_DIR%"

REM Set environment variables if using tools versions
if exist "%TOOLS_DIR%\jdk-%JAVA_VERSION%" (
    set "JAVA_HOME=%TOOLS_DIR%\jdk-%JAVA_VERSION%"
    set "PATH=%JAVA_HOME%\bin;%PATH%"
)

if exist "%TOOLS_DIR%\apache-maven-%MAVEN_VERSION%" (
    set "MAVEN_HOME=%TOOLS_DIR%\apache-maven-%MAVEN_VERSION%"
    set "PATH=%MAVEN_HOME%\bin;%PATH%"
)

REM Display versions
echo Using Java version:
java -version
echo.
echo Using Maven version:
mvn -version
echo.

REM Clean and run the application
echo Building and starting the application...
echo =========================================
mvn clean spring-boot:run

echo.
echo Backend-extended service stopped.
pause
