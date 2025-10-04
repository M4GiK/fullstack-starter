#!/bin/bash

# Script to start backend-extended service using Docker
# No local Java or Maven installation required!

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Get the directory where the script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$SCRIPT_DIR"
BACKEND_DIR="$PROJECT_ROOT/apps/backend_extended"

# Docker image and container names
IMAGE_NAME="backend-extended"
CONTAINER_NAME="backend-extended-app"
NETWORK_NAME="fullstack-starter_default"

echo ""
echo "========================================="
echo "  Backend Extended - Docker Launch"
echo "========================================="
echo ""

# Function to check system resources
check_system_resources() {
    echo "Checking system resources..."

    # Check available disk space (require at least 5GB free)
    DISK_SPACE=$(df / | tail -1 | awk '{print $4}')
    DISK_SPACE_GB=$((DISK_SPACE / 1024 / 1024))

    if [ $DISK_SPACE_GB -lt 5 ]; then
        echo -e "${RED}✗ Insufficient disk space!${NC}"
        echo "  Required: 5GB free space"
        echo "  Available: ${DISK_SPACE_GB}GB"
        echo ""
        echo "Please free up some disk space and try again."
        exit 1
    fi

    echo -e "${GREEN}✓ Sufficient disk space available (${DISK_SPACE_GB}GB)${NC}"
}

# Function to check if port is available
check_port_availability() {
    echo "Checking port availability..."

    if lsof -i :8081 &> /dev/null; then
        echo -e "${RED}✗ Port 8081 is already in use!${NC}"
        echo ""
        echo "Please stop the service using port 8081 or use a different port."
        echo "You can check what's using the port with: lsof -i :8081"
        exit 1
    fi

    echo -e "${GREEN}✓ Port 8081 is available${NC}"
}

# Function to check if Docker is installed and running
check_docker() {
    if ! command -v docker &> /dev/null; then
        echo -e "${RED}✗ Docker is not installed!${NC}"
        echo ""
        echo "Please install Docker Desktop:"
        echo "  macOS: https://docs.docker.com/desktop/install/mac-install/"
        echo "  Linux: https://docs.docker.com/engine/install/"
        echo ""
        exit 1
    fi

    if ! docker info &> /dev/null; then
        echo -e "${RED}✗ Docker is not running!${NC}"
        echo ""
        echo "Please start Docker Desktop and try again."
        exit 1
    fi

    echo -e "${GREEN}✓ Docker is installed and running${NC}"
}

# Function to check if Docker Compose is available
check_docker_compose() {
    if docker compose version &> /dev/null; then
        COMPOSE_CMD="docker compose"
    elif command -v docker-compose &> /dev/null; then
        COMPOSE_CMD="docker-compose"
    else
        echo -e "${RED}✗ Docker Compose is not available!${NC}"
        exit 1
    fi
    echo -e "${GREEN}✓ Docker Compose is available${NC}"
}

# Function to start database if not running
start_database() {
    echo ""
    echo "Checking PostgreSQL database..."
    
    # Check if postgres container is running
    if docker ps --format '{{.Names}}' | grep -q "monorepo-starter-postgres"; then
        echo -e "${GREEN}✓ PostgreSQL database is already running${NC}"
    else
        echo -e "${YELLOW}⚠ PostgreSQL database is not running${NC}"
        echo "Starting database with docker-compose..."
        
        cd "$PROJECT_ROOT"
        $COMPOSE_CMD up -d database-postgres
        
        echo "Waiting for database to be ready..."
        sleep 5
        
        # Wait for postgres to be ready
        MAX_TRIES=30
        TRIES=0
        while [ $TRIES -lt $MAX_TRIES ]; do
            if docker exec monorepo-starter-postgres pg_isready -U postgres &> /dev/null; then
                echo -e "${GREEN}✓ Database is ready!${NC}"
                break
            fi
            echo -n "."
            sleep 1
            TRIES=$((TRIES + 1))
        done
        
        if [ $TRIES -eq $MAX_TRIES ]; then
            echo -e "${RED}✗ Database failed to start${NC}"
            exit 1
        fi
    fi
}

# Function to create Docker network if it doesn't exist
ensure_network() {
    if ! docker network ls | grep -q "$NETWORK_NAME"; then
        echo "Creating Docker network: $NETWORK_NAME"
        docker network create "$NETWORK_NAME" || true
    fi
}

# Function to build Docker image
build_image() {
    echo ""
    echo "========================================="
    echo "  Building Docker image..."
    echo "========================================="
    echo -e "${YELLOW}⚠ This may take several minutes (Maven build + Docker build)${NC}"
    echo -e "${YELLOW}💡 You can monitor progress in another terminal with: docker buildx ls${NC}"
    echo ""

    cd "$BACKEND_DIR"

    # Start build with timing
    START_TIME=$(date +%s)
    echo "Starting Docker build at $(date)"

    if docker build -t "$IMAGE_NAME:latest" . ; then
        END_TIME=$(date +%s)
        BUILD_TIME=$((END_TIME - START_TIME))
        echo -e "${GREEN}✓ Docker image built successfully in ${BUILD_TIME}s!${NC}"
    else
        echo -e "${RED}✗ Failed to build Docker image${NC}"
        echo ""
        echo "Possible solutions:"
        echo "  1. Check if Maven build failed: cd apps/backend_extended && mvn clean package -DskipTests"
        echo "  2. Clear Docker cache: docker system prune -f"
        echo "  3. Try with --no-cache: docker build --no-cache -t $IMAGE_NAME:latest ."
        exit 1
    fi
}

# Function to check if backend-extended is already running
check_existing_service() {
    echo "Checking if backend-extended is already running..."

    if docker ps --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
        echo -e "${GREEN}✓ Backend-extended container is already running${NC}"

        # Test if API is responding
        if curl -s http://localhost:8081/api/health &> /dev/null; then
            echo -e "${GREEN}✓ API endpoints are accessible${NC}"
            echo ""
            echo -e "${YELLOW}Service is already running. Use these commands if you need to restart:${NC}"
            echo "  Stop:  docker stop $CONTAINER_NAME"
            echo "  Start: $0"
            echo ""
            echo -e "${BLUE}📝 Service URL:${NC} http://localhost:8081"
            exit 0
        else
            echo -e "${YELLOW}⚠ Container running but API not responding${NC}"
            echo "Stopping unhealthy container..."
            docker stop "$CONTAINER_NAME" &> /dev/null || true
            docker rm "$CONTAINER_NAME" &> /dev/null || true
        fi
    fi
}

# Function to stop existing container
stop_existing_container() {
    if docker ps -a --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
        echo ""
        echo "Stopping and removing existing container..."
        docker stop "$CONTAINER_NAME" &> /dev/null || true
        docker rm "$CONTAINER_NAME" &> /dev/null || true
        echo -e "${GREEN}✓ Existing container removed${NC}"
    fi
}

# Function to run Docker container
run_container() {
    echo ""
    echo "========================================="
    echo "  Starting Backend Extended container..."
    echo "========================================="
    
    # Determine database host
    # If database is in docker-compose network, use container name
    # Otherwise use host.docker.internal for Docker Desktop
    DB_HOST="host.docker.internal"
    
    # Check if we're on Linux (doesn't support host.docker.internal by default)
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        DB_HOST="172.17.0.1"  # Docker bridge network gateway
    fi
    
    # Try to connect to the docker-compose network first
    if docker network ls | grep -q "fullstack-starter_default"; then
        NETWORK_OPTION="--network fullstack-starter_default"
        DB_HOST="database-postgres"
    else
        NETWORK_OPTION=""
    fi
    
    docker run -d \
        --name "$CONTAINER_NAME" \
        -p 8081:8081 \
        -e "SPRING_DATASOURCE_URL=jdbc:postgresql://${DB_HOST}:5432/monorepo-starter" \
        -e "SPRING_DATASOURCE_USERNAME=postgres" \
        -e "SPRING_DATASOURCE_PASSWORD=postgres" \
        -e "SPRING_JPA_HIBERNATE_DDL_AUTO=validate" \
        $NETWORK_OPTION \
        "$IMAGE_NAME:latest"
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ Container started successfully!${NC}"

        # Wait for application to be ready
        echo "Waiting for application to start..."
        MAX_WAIT=60
        WAIT_COUNT=0

        while [ $WAIT_COUNT -lt $MAX_WAIT ]; do
            if docker logs "$CONTAINER_NAME" 2>&1 | grep -q "Started BackendExtendedApplication"; then
                echo -e "${GREEN}✓ Application started successfully!${NC}"
                break
            fi

            echo -n "."
            sleep 2
            WAIT_COUNT=$((WAIT_COUNT + 1))
        done

        if [ $WAIT_COUNT -eq $MAX_WAIT ]; then
            echo -e "${YELLOW}⚠ Application may still be starting...${NC}"
            echo "Check logs with: docker logs -f $CONTAINER_NAME"
        fi

        echo ""
        echo "========================================="
        echo "  Backend Extended is now running!"
        echo "========================================="
        echo ""
        echo -e "${BLUE}📝 Service URL:${NC} http://localhost:8081"
        echo -e "${BLUE}📊 Health Check:${NC} http://localhost:8081/api/health"
        echo -e "${BLUE}👥 Users API:${NC} http://localhost:8081/api/users"
        echo ""
        echo -e "${YELLOW}Useful commands:${NC}"
        echo "  View logs:          docker logs -f $CONTAINER_NAME"
        echo "  Stop container:     docker stop $CONTAINER_NAME"
        echo "  Remove container:   docker rm $CONTAINER_NAME"
        echo "  Restart container:  docker restart $CONTAINER_NAME"
        echo ""

    else
        echo -e "${RED}✗ Failed to start container${NC}"
        echo ""
        echo "Possible solutions:"
        echo "  1. Check if port 8081 is free: lsof -i :8081"
        echo "  2. Clean up old containers: docker rm $(docker ps -aq)"
        echo "  3. Check Docker logs: docker logs $CONTAINER_NAME"
        exit 1
    fi
}

# Function to show final status
show_final_status() {
    echo ""
    echo "========================================="
    echo "  🚀 Backend Extended Status Check"
    echo "========================================="

    # Check if container is running
    if docker ps --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
        echo -e "${GREEN}✓ Container is running${NC}"

        # Check health endpoint
        if curl -s http://localhost:8081/api/health &> /dev/null; then
            echo -e "${GREEN}✓ Health check passed${NC}"
            echo -e "${GREEN}✓ API endpoints are accessible${NC}"
        else
            echo -e "${YELLOW}⚠ Health check failed - container may still be starting${NC}"
        fi

        echo ""
        echo -e "${BLUE}📝 Service URL:${NC} http://localhost:8081"
        echo -e "${BLUE}📊 Health Check:${NC} http://localhost:8081/api/health"
        echo -e "${BLUE}👥 Users API:${NC} http://localhost:8081/api/users"

    else
        echo -e "${RED}✗ Container is not running${NC}"
        echo ""
        echo "Check logs with: docker logs $CONTAINER_NAME"
        return 1
    fi
}

# Main execution
main() {
    check_system_resources
    check_port_availability
    check_docker
    check_docker_compose
    check_existing_service
    start_database
    build_image
    stop_existing_container
    run_container
    show_final_status
}

# Run main function
main
