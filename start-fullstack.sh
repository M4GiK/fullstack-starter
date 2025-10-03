#!/bin/bash

# Fullstack Starter - Complete Development Environment Launcher
# Compatible with macOS and Linux
# Starts: Database, Backend (Node.js), Backend Extended (Java), Frontend

set -e

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

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

# Function to check if a process is running on a port
check_port() {
    local port=$1
    if lsof -Pi :$port -sTCP:LISTEN -t >/dev/null ; then
        return 0
    else
        return 1
    fi
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


# Function to start database and backend-extended
start_database_and_backend_extended() {
    log_info "Starting database and backend-extended services..."
    if command -v docker-compose &> /dev/null; then
        docker-compose up -d database-postgres localstack backend-extended
        wait_for_service "PostgreSQL" "localhost" "5432"
        wait_for_service "Backend Extended" "localhost" "8081"
    elif command -v docker &> /dev/null && docker compose version &> /dev/null; then
        docker compose up -d database-postgres localstack backend-extended
        wait_for_service "PostgreSQL" "localhost" "5432"
        wait_for_service "Backend Extended" "localhost" "8081"
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

    # Kill background processes (Node.js and React apps)
    if [ ! -z "$FRONTEND_PID" ]; then
        kill $FRONTEND_PID 2>/dev/null || true
    fi
    if [ ! -z "$BACKEND_PID" ]; then
        kill $BACKEND_PID 2>/dev/null || true
    fi

    # Stop Docker services (database, localstack, backend-extended)
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

    # Start Docker services (database + backend-extended)
    start_database_and_backend_extended
    echo ""

    # Start Node.js applications
    start_backend
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
