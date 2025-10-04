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

# Function to check system resources
check_system_resources() {
    log_info "Checking system resources..."

    # Check available disk space (require at least 5GB free)
    DISK_SPACE=$(df / | tail -1 | awk '{print $4}')
    DISK_SPACE_GB=$((DISK_SPACE / 1024 / 1024))

    if [ $DISK_SPACE_GB -lt 5 ]; then
        log_error "Insufficient disk space!"
        log_info "Required: 5GB free space"
        log_info "Available: ${DISK_SPACE_GB}GB"
        echo ""
        log_info "Please free up some disk space and try again."
        exit 1
    fi

    log_success "Sufficient disk space available (${DISK_SPACE_GB}GB)"
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

# Function to check port availability and show warning if occupied
check_port_availability() {
    local service=$1
    local port=$2

    log_info "Checking port availability for $service (port $port)..."

    if check_port $port; then
        log_warning "Port $port is already in use by $service"
        log_info "This might be from a previous run. The script will attempt to reuse existing services."
        return 1
    else
        log_success "Port $port is available"
        return 0
    fi
}

# Function to check if Docker is running
check_docker() {
    log_info "Checking Docker status..."

    if ! command -v docker &> /dev/null; then
        log_error "Docker is not installed!"
        log_info "Please install Docker Desktop:"
        echo "  macOS: https://docs.docker.com/desktop/install/mac-install/"
        echo "  Linux: https://docs.docker.com/engine/install/"
        exit 1
    fi

    if ! docker info &> /dev/null; then
        log_error "Docker is not running!"
        log_info "Please start Docker Desktop and try again."
        exit 1
    fi

    log_success "Docker is installed and running"
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


# Function to check if backend-extended is already running and healthy
check_backend_extended_status() {
    log_info "Checking backend-extended service status..."

    # Check if container is running
    if docker ps --format '{{.Names}}' | grep -q "^monorepo-starter-backend-extended$"; then
        log_success "Backend-extended container is running"

        # Test API endpoints
        if curl -s --max-time 5 http://localhost:8081/api/health &> /dev/null; then
            log_success "Backend-extended API is responding"
            return 0  # Already running and healthy
        else
            log_warning "Backend-extended container running but API not responding"
            log_info "Will restart the service..."
            return 1  # Needs restart
        fi
    else
        log_info "Backend-extended is not running"
        return 1  # Not running
    fi
}

# Function to start database and backend-extended
start_database_and_backend_extended() {
    log_info "Starting database and backend-extended services..."

    # Check if backend-extended is already running
    if check_backend_extended_status; then
        log_success "Using existing backend-extended service"
    else
        log_info "Starting fresh backend-extended service..."
    fi

    if command -v docker-compose &> /dev/null; then
        docker-compose up -d database-postgres localstack backend-extended
    elif command -v docker &> /dev/null && docker compose version &> /dev/null; then
        docker compose up -d database-postgres localstack backend-extended
    else
        log_error "Docker Compose is required but not found."
        log_info "Please install Docker and Docker Compose to continue."
        exit 1
    fi

    # Wait for services to be ready
    wait_for_service "PostgreSQL" "localhost" "5432"
    wait_for_service "Backend Extended" "localhost" "8081"

    # Additional check for backend-extended API
    log_info "Verifying backend-extended API endpoints..."
    if curl -s --max-time 10 http://localhost:8081/api/users &> /dev/null; then
        log_success "Backend-extended API is accessible"
    else
        log_warning "Backend-extended API check failed, but service might still be starting..."
    fi
}

# Function to check if backend (Node.js) is already running
check_backend_status() {
    log_info "Checking backend (Node.js) service status..."

    # Check if port 3001 is in use
    if check_port 3001; then
        log_success "Backend (Node.js) appears to be running on port 3001"

        # Test API endpoint
        if curl -s --max-time 5 http://localhost:3001/api/health &> /dev/null; then
            log_success "Backend API is responding"
            return 0  # Already running and healthy
        else
            log_warning "Backend port occupied but API not responding"
            return 1  # Port occupied but unhealthy
        fi
    else
        log_info "Backend (Node.js) is not running"
        return 1  # Not running
    fi
}

# Function to start backend (Node.js)
start_backend() {
    log_info "Starting backend (Node.js)..."

    # Check if backend is already running
    if check_backend_status; then
        log_success "Using existing backend (Node.js) service"
        return
    fi

    # Check if Node.js is installed
    if ! command -v node &> /dev/null; then
        log_error "Node.js is required but not found."
        log_info "Please install Node.js (version 18+) to continue."
        exit 1
    fi

    # Check Node.js version (require minimum 16)
    NODE_VERSION=$(node -v | sed 's/v//' | cut -d. -f1)
    if [ "$NODE_VERSION" -lt 16 ]; then
        log_error "Node.js version 16 or higher is required."
        log_info "Current version: $(node -v)"
        exit 1
    fi

    log_success "Node.js version: $(node -v)"

    # Navigate to backend directory and start
    cd "$PROJECT_DIR/apps/backend"

    # Check if dependencies are installed
    if [ ! -d "node_modules" ]; then
        log_info "Installing backend dependencies..."
        log_info "This may take a few minutes..."
        START_TIME=$(date +%s)
        if ! npm install; then
            log_error "Failed to install backend dependencies"
            cd "$PROJECT_DIR"
            exit 1
        fi
        END_TIME=$(date +%s)
        INSTALL_TIME=$((END_TIME - START_TIME))
        log_success "Dependencies installed in ${INSTALL_TIME}s"
    else
        log_info "Backend dependencies already installed"
    fi

    # Start backend in background
    log_info "Starting backend development server..."
    npm run dev &
    BACKEND_PID=$!

    # Wait for backend to be ready
    if wait_for_service "Backend" "localhost" "3001"; then
        log_success "Backend started successfully"
    else
        log_error "Backend failed to start properly"
        cd "$PROJECT_DIR"
        exit 1
    fi

    cd "$PROJECT_DIR"
}


# Function to check if frontend (React) is already running
check_frontend_status() {
    log_info "Checking frontend (React) service status..."

    # Check if port 5173 is in use (Vite dev server)
    if check_port 5173; then
        log_success "Frontend (React) appears to be running on port 5173"

        # Test if the dev server is responding
        if curl -s --max-time 5 http://localhost:5173 &> /dev/null; then
            log_success "Frontend dev server is responding"
            return 0  # Already running and healthy
        else
            log_warning "Frontend port occupied but dev server not responding"
            return 1  # Port occupied but unhealthy
        fi
    else
        log_info "Frontend (React) is not running"
        return 1  # Not running
    fi
}

# Function to start frontend
start_frontend() {
    log_info "Starting frontend (React)..."

    # Check if frontend is already running
    if check_frontend_status; then
        log_success "Using existing frontend (React) service"
        return
    fi

    # Navigate to frontend directory
    cd "$PROJECT_DIR/apps/frontend"

    # Check if dependencies are installed
    if [ ! -d "node_modules" ]; then
        log_info "Installing frontend dependencies..."
        log_info "This may take a few minutes..."
        START_TIME=$(date +%s)
        if ! npm install; then
            log_error "Failed to install frontend dependencies"
            cd "$PROJECT_DIR"
            exit 1
        fi
        END_TIME=$(date +%s)
        INSTALL_TIME=$((END_TIME - START_TIME))
        log_success "Dependencies installed in ${INSTALL_TIME}s"
    else
        log_info "Frontend dependencies already installed"
    fi

    # Start frontend in background
    log_info "Starting frontend development server..."
    npm run dev &
    FRONTEND_PID=$!

    # Wait for frontend to be ready
    if wait_for_service "Frontend" "localhost" "5173"; then
        log_success "Frontend started successfully"
    else
        log_error "Frontend failed to start properly"
        cd "$PROJECT_DIR"
        exit 1
    fi

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

# Function to show final status summary
show_final_status() {
    echo ""
    echo "========================================="
    log_success "🎉 Fullstack Development Environment Status"
    echo "========================================="

    local all_healthy=true

    # Check each service
    echo ""

    # Frontend
    if check_port 5173 && curl -s --max-time 3 http://localhost:5173 &> /dev/null; then
        log_success "✅ Frontend (React):    http://localhost:5173"
    else
        log_error "❌ Frontend (React):    http://localhost:5173"
        all_healthy=false
    fi

    # Backend (Node.js)
    if check_port 3001 && curl -s --max-time 3 http://localhost:3001/api/health &> /dev/null; then
        log_success "✅ Backend (Node.js):   http://localhost:3001"
    else
        log_error "❌ Backend (Node.js):   http://localhost:3001"
        all_healthy=false
    fi

    # Backend Extended (Java)
    if docker ps --format '{{.Names}}' | grep -q "^monorepo-starter-backend-extended$" && \
       curl -s --max-time 3 http://localhost:8081/api/users &> /dev/null; then
        log_success "✅ Backend Extended:  http://localhost:8081"
    else
        log_error "❌ Backend Extended:  http://localhost:8081"
        all_healthy=false
    fi

    # Database
    if docker ps --format '{{.Names}}' | grep -q "^monorepo-starter-postgres$"; then
        log_success "✅ Database:          localhost:5432"
    else
        log_error "❌ Database:          localhost:5432"
        all_healthy=false
    fi

    # LocalStack
    if docker ps --format '{{.Names}}' | grep -q "^monorepo-starter-localstack$"; then
        log_success "✅ LocalStack:        http://localhost:4566"
    else
        log_error "❌ LocalStack:        http://localhost:4566"
        all_healthy=false
    fi

    echo ""
    if [ "$all_healthy" = true ]; then
        log_success "🎉 All services are running and healthy!"
        echo ""
        log_info "Useful commands:"
        echo "  View logs:     docker-compose logs -f [service-name]"
        echo "  Stop all:      docker-compose down"
        echo "  Restart:       $0"
    else
        log_warning "⚠️  Some services may not be fully operational"
        log_info "Check individual service logs for more details"
    fi
}

# Main execution
main() {
    log_info "🚀 Starting Fullstack Starter Development Environment"
    echo ""

    # Pre-flight checks
    check_system_resources
    check_docker
    echo ""

    # Check port availability (warnings only, don't fail)
    check_port_availability "Frontend" 5173
    check_port_availability "Backend (Node.js)" 3001
    check_port_availability "Backend Extended" 8081
    echo ""

    # Start Docker services (database + backend-extended)
    start_database_and_backend_extended
    echo ""

    # Start Node.js applications
    start_backend
    echo ""

    start_frontend
    echo ""

    # Final status check
    show_final_status
    echo ""
    log_info "Press Ctrl+C to stop all services"

    # Wait for user interrupt
    wait
}

# Run main function
main "$@"
