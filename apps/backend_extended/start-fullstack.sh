#!/bin/bash

# Fullstack Starter - Complete Development Environment Launcher
# Compatible with macOS and Linux
# Starts: Database, Backend (Node.js), Backend Extended (Java), Frontend

set -e

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TOOLS_DIR="$PROJECT_DIR/tools"
SDKMAN_DIR="$TOOLS_DIR/sdkman"
JAVA_DIR="$TOOLS_DIR/java21"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to wait for a service to be ready
wait_for_service() {
    local service_name=$1
    local host=$2
    local port=$3
    local max_attempts=30
    local attempt=1

    log_info "Waiting for $service_name to be ready on $host:$port..."

    while [ $attempt -le $max_attempts ]; do
        if nc -z $host $port 2>/dev/null; then
            log_success "$service_name is ready!"
            return 0
        fi

        log_info "Attempt $attempt/$max_attempts - $service_name not ready yet..."
        sleep 2
        ((attempt++))
    done

    log_error "$service_name failed to start within expected time"
    return 1
}

# Function to setup SDKMAN locally for Java
setup_java() {
    log_info "Setting up Java 21 locally for backend-extended..."

    if [ ! -d "$SDKMAN_DIR" ]; then
        mkdir -p "$SDKMAN_DIR"
        curl -s "https://get.sdkman.io" | bash -s --silent > /dev/null
        mv "$HOME/.sdkman" "$SDKMAN_DIR"
    fi

    export SDKMAN_DIR="$SDKMAN_DIR"
    source "$SDKMAN_DIR/bin/sdkman-init.sh"

    # Install Java 21 locally
    if [ ! -d "$JAVA_DIR" ]; then
        log_info "Installing Java 21..."
        sdk install java 21.0.2-tem < /dev/null
        sdk use java 21.0.2-tem
        # Copy Java to local directory to avoid conflicts
        cp -r "$SDKMAN_DIR/candidates/java/current" "$JAVA_DIR"
    fi
}

# Function to start database
start_database() {
    log_info "Starting database services..."
    if command -v docker-compose &> /dev/null; then
        docker-compose up -d database-postgres localstack
        wait_for_service "PostgreSQL" "localhost" "5432"
    elif command -v docker &> /dev/null && docker compose version &> /dev/null; then
        docker compose up -d database-postgres localstack
        wait_for_service "PostgreSQL" "localhost" "5432"
    else
        log_error "Docker Compose is required but not found."
        log_info "Please install Docker and Docker Compose to continue."
        exit 1
    fi
}

# Function to start backend (Node.js)
start_backend() {
    log_info "Starting backend (Node.js)..."

    # Check if Node.js is installed
    if ! command -v node &> /dev/null; then
        log_error "Node.js is required but not found."
        exit 1
    fi

    # Navigate to backend directory and start
    cd "$PROJECT_DIR/apps/backend"

    # Check if dependencies are installed
    if [ ! -d "node_modules" ]; then
        log_info "Installing backend dependencies..."
        npm install
    fi

    # Start backend in background
    npm run dev &
    BACKEND_PID=$!

    # Wait for backend to be ready
    wait_for_service "Backend" "localhost" "3001"

    cd "$PROJECT_DIR"
}

# Function to start backend-extended (Java)
start_backend_extended() {
    log_info "Starting backend-extended (Java)..."

    # Check if Java 21 is available globally
    if java -version 2>&1 | grep -q "21"; then
        log_info "Using globally installed Java 21"
    else
        log_info "Java 21 not found globally, setting up local Java..."
        setup_java
        export JAVA_HOME="$JAVA_DIR"
        export PATH="$JAVA_HOME/bin:$PATH"
    fi

    # Navigate to backend_extended directory
    cd "$PROJECT_DIR/apps/backend_extended"

    # Start backend-extended in background
    ./mvnw spring-boot:run &
    BACKEND_EXTENDED_PID=$!

    # Wait for backend-extended to be ready
    wait_for_service "Backend Extended" "localhost" "8081"

    cd "$PROJECT_DIR"
}

# Function to start frontend
start_frontend() {
    log_info "Starting frontend (React)..."

    # Navigate to frontend directory
    cd "$PROJECT_DIR/apps/frontend"

    # Check if dependencies are installed
    if [ ! -d "node_modules" ]; then
        log_info "Installing frontend dependencies..."
        npm install
    fi

    # Start frontend in background
    npm run dev &
    FRONTEND_PID=$!

    # Wait for frontend to be ready
    wait_for_service "Frontend" "localhost" "5173"

    cd "$PROJECT_DIR"
}

# Function to stop all services
stop_services() {
    log_warning "Stopping all services..."

    # Kill background processes
    if [ ! -z "$BACKEND_PID" ]; then
        kill $BACKEND_PID 2>/dev/null || true
    fi
    if [ ! -z "$BACKEND_EXTENDED_PID" ]; then
        kill $BACKEND_EXTENDED_PID 2>/dev/null || true
    fi
    if [ ! -z "$FRONTEND_PID" ]; then
        kill $FRONTEND_PID 2>/dev/null || true
    fi

    # Stop Docker services
    if command -v docker-compose &> /dev/null; then
        docker-compose down
    elif command -v docker &> /dev/null && docker compose version &> /dev/null; then
        docker compose down
    fi

    log_success "All services stopped."
    exit 0
}

# Trap SIGINT (Ctrl+C) to stop services
trap stop_services SIGINT

# Main execution
main() {
    log_info "🚀 Starting Fullstack Starter Development Environment"
    echo ""

    # Start services in order
    start_database
    echo ""

    start_backend
    echo ""

    start_backend_extended
    echo ""

    start_frontend
    echo ""

    log_success "🎉 All services are running!"
    echo ""
    log_info "📊 Service URLs:"
    echo "  🌐 Frontend:     http://localhost:5173"
    echo "  🔧 Backend:      http://localhost:3001"
    echo "  ⚡ Backend Ext:  http://localhost:8081"
    echo "  🗄️  Database:    localhost:5432"
    echo "  ☁️  LocalStack:  http://localhost:4566"
    echo ""
    log_info "Press Ctrl+C to stop all services"

    # Wait for user interrupt
    wait
}

# Run main function
main "$@"
