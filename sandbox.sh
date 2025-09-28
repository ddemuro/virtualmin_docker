#!/bin/bash
# Virtualmin Docker Sandbox Script
# Provides test, install, debug, and publish capabilities

set -e

# Configuration
REGISTRY="dkr.takelan.com"
NAMESPACE="takelan"
IMAGE_NAME="dockermin"
FULL_IMAGE="${REGISTRY}/${NAMESPACE}/${IMAGE_NAME}"
LOCAL_IMAGE="virtualmin:latest"
CONTAINER_NAME="tkvmin"
COMPOSE_PROJECT="virtualmin"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Version management
VERSION_FILE=".version"
if [ -f "$VERSION_FILE" ]; then
    VERSION=$(cat "$VERSION_FILE")
else
    VERSION="1.0.0"
    echo "$VERSION" > "$VERSION_FILE"
fi

# Function to display header
show_header() {
    echo -e "${CYAN}========================================${NC}"
    echo -e "${CYAN}Virtualmin Docker Sandbox${NC}"
    echo -e "${CYAN}Version: ${VERSION}${NC}"
    echo -e "${CYAN}========================================${NC}"
}

# Function to display usage
show_usage() {
    echo -e "${YELLOW}Usage: $0 [command] [options]${NC}"
    echo ""
    echo -e "${GREEN}Commands:${NC}"
    echo -e "  ${BLUE}build${NC}      - Build the Docker image"
    echo -e "  ${BLUE}test${NC}       - Run comprehensive tests"
    echo -e "  ${BLUE}install${NC}    - Install and start the container"
    echo -e "  ${BLUE}debug${NC}      - Debug the container"
    echo -e "  ${BLUE}publish${NC}    - Publish image to private registry"
    echo -e "  ${BLUE}clean${NC}      - Clean up containers and images"
    echo -e "  ${BLUE}status${NC}     - Show container status"
    echo -e "  ${BLUE}logs${NC}       - Show container logs"
    echo -e "  ${BLUE}shell${NC}      - Open shell in container"
    echo -e "  ${BLUE}backup${NC}     - Create container backup"
    echo -e "  ${BLUE}restore${NC}    - Restore from backup"
    echo -e "  ${BLUE}update${NC}     - Update OS and Virtualmin in container"
    echo -e "  ${BLUE}version${NC}    - Manage version numbers"
    echo -e "  ${BLUE}validate${NC}   - Validate configuration files"
    echo -e "  ${BLUE}monitor${NC}    - Access monitoring dashboard URLs"
    echo -e "  ${BLUE}metrics${NC}    - Show current metrics"
    echo ""
    echo -e "${GREEN}Options:${NC}"
    echo -e "  --force    - Force operation (skip confirmations)"
    echo -e "  --tag      - Specify custom tag for publish"
    echo -e "  --no-cache - Build without cache"
    echo -e "  --verbose  - Verbose output"
    echo ""
    echo -e "${GREEN}Examples:${NC}"
    echo -e "  $0 build --no-cache"
    echo -e "  $0 test --verbose"
    echo -e "  $0 publish --tag v1.2.3"
    echo -e "  $0 debug --service apache2"
}

# Function to check prerequisites
check_prerequisites() {
    local missing=0

    echo -e "${YELLOW}Checking prerequisites...${NC}"

    # Check Docker
    if ! command -v docker &> /dev/null; then
        echo -e "${RED}✗ Docker is not installed${NC}"
        missing=1
    else
        echo -e "${GREEN}✓ Docker found${NC}"
    fi

    # Check Docker Compose
    if ! command -v docker-compose &> /dev/null; then
        echo -e "${RED}✗ Docker Compose is not installed${NC}"
        missing=1
    else
        echo -e "${GREEN}✓ Docker Compose found${NC}"
    fi

    # Check .env file
    if [ ! -f ".env" ]; then
        echo -e "${YELLOW}⚠ .env file not found, creating from template${NC}"
        if [ -f ".env-template" ]; then
            cp .env-template .env
            echo -e "${GREEN}✓ Created .env file from template${NC}"
            echo -e "${YELLOW}  Please edit .env file with your settings${NC}"
        else
            echo -e "${RED}✗ .env-template not found${NC}"
            missing=1
        fi
    else
        echo -e "${GREEN}✓ .env file found${NC}"
    fi

    if [ $missing -eq 1 ]; then
        echo -e "${RED}Missing prerequisites. Please install required tools.${NC}"
        exit 1
    fi
}

# Function to build the image
build_image() {
    echo -e "${CYAN}Building Docker image...${NC}"

    local cache_opt=""
    if [[ "$*" == *"--no-cache"* ]]; then
        cache_opt="--no-cache"
        echo -e "${YELLOW}Building without cache${NC}"
    fi

    # Build with docker-compose
    docker-compose build $cache_opt tkvmin

    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ Image built successfully${NC}"

        # Tag the image
        docker tag ${LOCAL_IMAGE} ${FULL_IMAGE}:${VERSION}
        docker tag ${LOCAL_IMAGE} ${FULL_IMAGE}:latest

        echo -e "${GREEN}✓ Image tagged as:${NC}"
        echo -e "  - ${FULL_IMAGE}:${VERSION}"
        echo -e "  - ${FULL_IMAGE}:latest"
    else
        echo -e "${RED}✗ Build failed${NC}"
        exit 1
    fi
}

# Function to run tests
run_tests() {
    echo -e "${CYAN}Running tests...${NC}"

    local verbose=""
    if [[ "$*" == *"--verbose"* ]]; then
        verbose="--verbose"
    fi

    # Start container for testing
    echo -e "${YELLOW}Starting test container...${NC}"
    docker-compose up -d tkvmin

    # Wait for container to be ready
    echo -e "${YELLOW}Waiting for container to initialize...${NC}"
    sleep 30

    # Test suite
    echo -e "${BLUE}Running test suite...${NC}"

    # Test 1: Check if services are running
    echo -e "${YELLOW}Test 1: Checking services...${NC}"
    local services=("apache2" "mysql" "postfix" "dovecot" "sshd" "named")
    for service in "${services[@]}"; do
        if docker exec ${CONTAINER_NAME} pgrep -x "$service" > /dev/null; then
            echo -e "${GREEN}  ✓ $service is running${NC}"
        else
            echo -e "${RED}  ✗ $service is not running${NC}"
        fi
    done

    # Test 2: Check web services
    echo -e "${YELLOW}Test 2: Checking web services...${NC}"
    if curl -f -s http://localhost > /dev/null; then
        echo -e "${GREEN}  ✓ Apache is responding${NC}"
    else
        echo -e "${RED}  ✗ Apache is not responding${NC}"
    fi

    if curl -f -s -k https://localhost:10000 > /dev/null; then
        echo -e "${GREEN}  ✓ Webmin/Virtualmin is responding${NC}"
    else
        echo -e "${RED}  ✗ Webmin/Virtualmin is not responding${NC}"
    fi

    # Test 3: Check PHP versions
    echo -e "${YELLOW}Test 3: Checking PHP versions...${NC}"
    local php_versions=("5.6" "7.0" "7.1" "7.2" "7.3" "7.4" "8.0" "8.1" "8.2" "8.3")
    for version in "${php_versions[@]}"; do
        if docker exec ${CONTAINER_NAME} php${version} -v > /dev/null 2>&1; then
            echo -e "${GREEN}  ✓ PHP ${version} is installed${NC}"
        else
            echo -e "${YELLOW}  ⚠ PHP ${version} not found${NC}"
        fi
    done

    # Test 4: Check database connectivity
    echo -e "${YELLOW}Test 4: Checking database...${NC}"
    if docker exec ${CONTAINER_NAME} mysqladmin -u root ping > /dev/null 2>&1; then
        echo -e "${GREEN}  ✓ MySQL is accessible${NC}"
    else
        echo -e "${RED}  ✗ MySQL is not accessible${NC}"
    fi

    # Test 5: Check mail services
    echo -e "${YELLOW}Test 5: Checking mail services...${NC}"
    if docker exec ${CONTAINER_NAME} postconf -d > /dev/null 2>&1; then
        echo -e "${GREEN}  ✓ Postfix configuration is valid${NC}"
    else
        echo -e "${RED}  ✗ Postfix configuration error${NC}"
    fi

    # Test 6: Check DNS
    echo -e "${YELLOW}Test 6: Checking DNS service...${NC}"
    if docker exec ${CONTAINER_NAME} named-checkconf > /dev/null 2>&1; then
        echo -e "${GREEN}  ✓ BIND configuration is valid${NC}"
    else
        echo -e "${RED}  ✗ BIND configuration error${NC}"
    fi

    # Test 7: Health check
    echo -e "${YELLOW}Test 7: Container health check...${NC}"
    local health=$(docker inspect --format='{{.State.Health.Status}}' ${CONTAINER_NAME} 2>/dev/null || echo "none")
    if [ "$health" == "healthy" ]; then
        echo -e "${GREEN}  ✓ Container is healthy${NC}"
    elif [ "$health" == "none" ]; then
        echo -e "${YELLOW}  ⚠ No health check configured${NC}"
    else
        echo -e "${RED}  ✗ Container health: $health${NC}"
    fi

    echo -e "${GREEN}Testing completed!${NC}"
}

# Function to install and start container
install_container() {
    echo -e "${CYAN}Installing Virtualmin container...${NC}"

    check_prerequisites

    # Build image first
    build_image

    # Start all services
    echo -e "${YELLOW}Starting services...${NC}"
    docker-compose up -d

    # Wait for initialization
    echo -e "${YELLOW}Waiting for services to initialize...${NC}"
    sleep 30

    # Show status
    show_status

    echo -e "${GREEN}✓ Installation completed!${NC}"
    echo -e "${BLUE}Access points:${NC}"
    echo -e "  Virtualmin: ${CYAN}https://$(hostname -I | cut -d' ' -f1):10000${NC}"
    echo -e "  SSH: ${CYAN}ssh root@$(hostname -I | cut -d' ' -f1) -p 22${NC}"
    echo -e "  phpMyAdmin: ${CYAN}http://$(hostname -I | cut -d' ' -f1):10081${NC}"
    echo -e "  phpLDAPadmin: ${CYAN}http://$(hostname -I | cut -d' ' -f1):10080${NC}"
}

# Function to debug container
debug_container() {
    echo -e "${CYAN}Debug Mode${NC}"

    if [ ! "$(docker ps -q -f name=${CONTAINER_NAME})" ]; then
        echo -e "${RED}Container is not running${NC}"
        echo -e "${YELLOW}Starting container...${NC}"
        docker-compose up -d tkvmin
        sleep 10
    fi

    # Parse debug options
    local service=""
    for arg in "$@"; do
        case $arg in
            --service=*)
                service="${arg#*=}"
                ;;
        esac
    done

    echo -e "${BLUE}Container Information:${NC}"
    docker inspect ${CONTAINER_NAME} | grep -E '"Status"|"Health"|"IPAddress"' | head -20

    echo -e "\n${BLUE}Running Processes:${NC}"
    docker exec ${CONTAINER_NAME} ps aux | head -20

    echo -e "\n${BLUE}Service Status:${NC}"
    docker exec ${CONTAINER_NAME} supervisorctl status 2>/dev/null || \
        docker exec ${CONTAINER_NAME} service --status-all 2>/dev/null || true

    echo -e "\n${BLUE}Recent Logs:${NC}"
    docker logs --tail 50 ${CONTAINER_NAME}

    if [ -n "$service" ]; then
        echo -e "\n${BLUE}Debug service: $service${NC}"
        docker exec ${CONTAINER_NAME} systemctl status $service 2>/dev/null || \
            docker exec ${CONTAINER_NAME} service $service status 2>/dev/null || true
    fi

    echo -e "\n${YELLOW}Opening debug shell...${NC}"
    echo -e "${CYAN}Type 'exit' to leave debug shell${NC}"
    docker exec -it ${CONTAINER_NAME} /bin/bash
}

# Function to publish image
publish_image() {
    echo -e "${CYAN}Publishing image to registry...${NC}"

    # Parse custom tag
    local custom_tag=""
    for arg in "$@"; do
        case $arg in
            --tag=*)
                custom_tag="${arg#*=}"
                ;;
        esac
    done

    # Use custom tag or version
    local tag=${custom_tag:-$VERSION}

    echo -e "${YELLOW}Publishing as: ${FULL_IMAGE}:${tag}${NC}"

    # Login to registry
    echo -e "${YELLOW}Logging into registry: ${REGISTRY}${NC}"
    docker login ${REGISTRY}

    if [ $? -ne 0 ]; then
        echo -e "${RED}✗ Failed to login to registry${NC}"
        exit 1
    fi

    # Tag images
    docker tag ${LOCAL_IMAGE} ${FULL_IMAGE}:${tag}
    docker tag ${LOCAL_IMAGE} ${FULL_IMAGE}:latest

    # Push images
    echo -e "${YELLOW}Pushing ${FULL_IMAGE}:${tag}...${NC}"
    docker push ${FULL_IMAGE}:${tag}

    echo -e "${YELLOW}Pushing ${FULL_IMAGE}:latest...${NC}"
    docker push ${FULL_IMAGE}:latest

    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ Image published successfully!${NC}"
        echo -e "${GREEN}  Registry: ${REGISTRY}${NC}"
        echo -e "${GREEN}  Repository: ${NAMESPACE}/${IMAGE_NAME}${NC}"
        echo -e "${GREEN}  Tags: ${tag}, latest${NC}"

        # Update version file if not using custom tag
        if [ -z "$custom_tag" ]; then
            increment_version
        fi
    else
        echo -e "${RED}✗ Failed to push image${NC}"
        exit 1
    fi
}

# Function to clean up
cleanup() {
    echo -e "${CYAN}Cleaning up...${NC}"

    local force=""
    if [[ "$*" != *"--force"* ]]; then
        read -p "This will stop and remove containers. Continue? (y/N) " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            echo -e "${YELLOW}Cleanup cancelled${NC}"
            exit 0
        fi
    fi

    echo -e "${YELLOW}Stopping containers...${NC}"
    docker-compose down

    echo -e "${YELLOW}Removing unused images...${NC}"
    docker image prune -f

    echo -e "${YELLOW}Removing unused volumes...${NC}"
    docker volume prune -f

    echo -e "${GREEN}✓ Cleanup completed${NC}"
}

# Function to show status
show_status() {
    echo -e "${CYAN}Container Status${NC}"

    if [ "$(docker ps -q -f name=${CONTAINER_NAME})" ]; then
        echo -e "${GREEN}✓ Container is running${NC}"

        # Show container details
        docker ps --filter "name=${CONTAINER_NAME}" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

        # Show service status inside container
        echo -e "\n${BLUE}Services:${NC}"
        docker exec ${CONTAINER_NAME} supervisorctl status 2>/dev/null || \
            echo "  Supervisor not running or not configured"

        # Show resource usage
        echo -e "\n${BLUE}Resource Usage:${NC}"
        docker stats --no-stream ${CONTAINER_NAME}
    else
        echo -e "${RED}✗ Container is not running${NC}"

        # Show stopped containers
        if [ "$(docker ps -aq -f name=${CONTAINER_NAME})" ]; then
            echo -e "${YELLOW}Container exists but is stopped${NC}"
            docker ps -a --filter "name=${CONTAINER_NAME}" --format "table {{.Names}}\t{{.Status}}"
        else
            echo -e "${YELLOW}Container does not exist${NC}"
        fi
    fi
}

# Function to show logs
show_logs() {
    echo -e "${CYAN}Container Logs${NC}"

    local follow=""
    local tail="100"

    for arg in "$@"; do
        case $arg in
            --follow|-f)
                follow="-f"
                ;;
            --tail=*)
                tail="${arg#*=}"
                ;;
        esac
    done

    if [ "$(docker ps -q -f name=${CONTAINER_NAME})" ]; then
        docker logs --tail ${tail} ${follow} ${CONTAINER_NAME}
    else
        echo -e "${RED}Container is not running${NC}"
    fi
}

# Function to open shell
open_shell() {
    echo -e "${CYAN}Opening shell in container...${NC}"

    if [ "$(docker ps -q -f name=${CONTAINER_NAME})" ]; then
        docker exec -it ${CONTAINER_NAME} /bin/bash
    else
        echo -e "${RED}Container is not running${NC}"
        echo -e "${YELLOW}Starting container...${NC}"
        docker-compose up -d tkvmin
        sleep 10
        docker exec -it ${CONTAINER_NAME} /bin/bash
    fi
}

# Function to backup container
backup_container() {
    echo -e "${CYAN}Creating backup...${NC}"

    if [ ! "$(docker ps -q -f name=${CONTAINER_NAME})" ]; then
        echo -e "${RED}Container is not running${NC}"
        exit 1
    fi

    local backup_type=""
    for arg in "$@"; do
        case $arg in
            --full)
                backup_type="--full"
                ;;
        esac
    done

    docker exec ${CONTAINER_NAME} /usr/local/bin/backup-container ${backup_type}

    # Copy backup to host
    echo -e "${YELLOW}Copying backup to host...${NC}"
    mkdir -p ./backups
    docker cp ${CONTAINER_NAME}:/data/backups/. ./backups/
    echo -e "${GREEN}✓ Backup saved to ./backups/${NC}"
}

# Function to restore container
restore_container() {
    echo -e "${CYAN}Restoring from backup...${NC}"

    local backup_file=""
    for arg in "$@"; do
        case $arg in
            --file=*)
                backup_file="${arg#*=}"
                ;;
        esac
    done

    if [ -z "$backup_file" ]; then
        echo -e "${RED}No backup file specified${NC}"
        echo "Usage: $0 restore --file=/path/to/backup.tar.gz"
        echo ""
        echo "Available backups:"
        ls -lh ./backups/*.tar.gz 2>/dev/null || echo "No backups found"
        exit 1
    fi

    if [ ! -f "$backup_file" ]; then
        echo -e "${RED}Backup file not found: $backup_file${NC}"
        exit 1
    fi

    # Copy backup to container
    docker cp "$backup_file" ${CONTAINER_NAME}:/tmp/restore.tar.gz

    # Run restore
    docker exec ${CONTAINER_NAME} /usr/local/bin/restore-container /tmp/restore.tar.gz --force

    echo -e "${GREEN}✓ Restore completed${NC}"
}

# Function to update container
update_container() {
    echo -e "${CYAN}Updating container...${NC}"

    if [ ! "$(docker ps -q -f name=${CONTAINER_NAME})" ]; then
        echo -e "${RED}Container is not running${NC}"
        exit 1
    fi

    echo -e "${YELLOW}Updating OS packages...${NC}"
    docker exec ${CONTAINER_NAME} /usr/local/bin/update-os

    echo -e "${YELLOW}Updating Virtualmin...${NC}"
    docker exec ${CONTAINER_NAME} /usr/local/bin/update-virtualmin

    echo -e "${GREEN}✓ Updates completed${NC}"
}

# Function to manage versions
manage_version() {
    local action="${2:-show}"

    case $action in
        show)
            echo -e "${CYAN}Current version: ${VERSION}${NC}"
            ;;
        bump|increment)
            increment_version
            ;;
        set)
            if [ -n "$3" ]; then
                VERSION="$3"
                echo "$VERSION" > "$VERSION_FILE"
                echo -e "${GREEN}Version set to: ${VERSION}${NC}"
            else
                echo -e "${RED}No version specified${NC}"
            fi
            ;;
        *)
            echo -e "${RED}Unknown version action: $action${NC}"
            echo "Usage: $0 version [show|bump|set VERSION]"
            ;;
    esac
}

# Function to increment version
increment_version() {
    local major=$(echo $VERSION | cut -d. -f1)
    local minor=$(echo $VERSION | cut -d. -f2)
    local patch=$(echo $VERSION | cut -d. -f3)

    patch=$((patch + 1))

    VERSION="${major}.${minor}.${patch}"
    echo "$VERSION" > "$VERSION_FILE"
    echo -e "${GREEN}Version bumped to: ${VERSION}${NC}"
}

# Function to show monitoring dashboards
show_monitoring() {
    echo -e "${CYAN}Monitoring Dashboard URLs${NC}"
    echo ""

    local host_ip=$(hostname -I | cut -d' ' -f1)

    echo -e "${GREEN}Grafana Dashboard:${NC}"
    echo -e "  URL: ${CYAN}http://${host_ip}:3000${NC}"
    echo -e "  Username: admin"
    echo -e "  Password: (from .env GRAFANA_PASSWORD)"
    echo ""

    echo -e "${GREEN}Prometheus Metrics:${NC}"
    echo -e "  URL: ${CYAN}http://${host_ip}:9090${NC}"
    echo ""

    echo -e "${GREEN}Container Metrics (cAdvisor):${NC}"
    echo -e "  URL: ${CYAN}http://${host_ip}:8080${NC}"
    echo ""

    echo -e "${GREEN}Node Exporter Metrics:${NC}"
    echo -e "  URL: ${CYAN}http://${host_ip}:9100/metrics${NC}"
    echo ""

    echo -e "${GREEN}Loki (Log Aggregation):${NC}"
    echo -e "  URL: ${CYAN}http://${host_ip}:3100${NC}"
    echo ""

    echo -e "${YELLOW}Quick Commands:${NC}"
    echo -e "  View logs: ${BLUE}docker logs grafana${NC}"
    echo -e "  Restart monitoring: ${BLUE}docker-compose restart grafana prometheus loki${NC}"
    echo -e "  Check metrics: ${BLUE}curl http://localhost:9090/metrics${NC}"
}

# Function to show current metrics
show_metrics() {
    echo -e "${CYAN}Current System Metrics${NC}"
    echo ""

    # Check if prometheus is running
    if [ ! "$(docker ps -q -f name=prometheus)" ]; then
        echo -e "${RED}Prometheus is not running${NC}"
        echo -e "Start monitoring with: ${BLUE}docker-compose up -d prometheus grafana${NC}"
        exit 1
    fi

    echo -e "${YELLOW}Fetching metrics from Prometheus...${NC}"

    # CPU Usage
    echo -e "\n${GREEN}CPU Usage:${NC}"
    curl -s "http://localhost:9090/api/v1/query?query=100-avg(irate(node_cpu_seconds_total{mode='idle'}[5m]))*100" | \
        grep -o '"value":\[.*\]' | sed 's/.*,"\([^"]*\)".*/\1/' | head -1 || echo "N/A"

    # Memory Usage
    echo -e "\n${GREEN}Memory Usage:${NC}"
    curl -s "http://localhost:9090/api/v1/query?query=(node_memory_MemTotal_bytes-node_memory_MemAvailable_bytes)/node_memory_MemTotal_bytes*100" | \
        grep -o '"value":\[.*\]' | sed 's/.*,"\([^"]*\)".*/\1/' | head -1 || echo "N/A"

    # Disk Usage
    echo -e "\n${GREEN}Disk Usage:${NC}"
    curl -s "http://localhost:9090/api/v1/query?query=100-(node_filesystem_free_bytes{mountpoint='/'}/node_filesystem_size_bytes{mountpoint='/'}*100)" | \
        grep -o '"value":\[.*\]' | sed 's/.*,"\([^"]*\)".*/\1/' | head -1 || echo "N/A"

    # Container Status
    echo -e "\n${GREEN}Container Status:${NC}"
    docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | grep -E "(prometheus|grafana|loki|node-exporter|cadvisor)"

    echo -e "\n${BLUE}For detailed metrics, visit:${NC}"
    echo -e "  Grafana: ${CYAN}http://localhost:3000${NC}"
    echo -e "  Prometheus: ${CYAN}http://localhost:9090${NC}"
}

# Function to validate configuration
validate_config() {
    echo -e "${CYAN}Validating configuration...${NC}"

    local errors=0

    # Check Dockerfile
    echo -e "${YELLOW}Checking Dockerfile...${NC}"
    if [ -f "Dockerfile" ]; then
        if docker build --no-cache -t test-build -f Dockerfile . --dry-run 2>/dev/null; then
            echo -e "${GREEN}  ✓ Dockerfile syntax is valid${NC}"
        else
            echo -e "${RED}  ✗ Dockerfile has syntax errors${NC}"
            errors=$((errors + 1))
        fi
    else
        echo -e "${RED}  ✗ Dockerfile not found${NC}"
        errors=$((errors + 1))
    fi

    # Check docker-compose.yml
    echo -e "${YELLOW}Checking docker-compose.yml...${NC}"
    if [ -f "docker-compose.yml" ]; then
        if docker-compose config > /dev/null 2>&1; then
            echo -e "${GREEN}  ✓ docker-compose.yml is valid${NC}"
        else
            echo -e "${RED}  ✗ docker-compose.yml has errors${NC}"
            docker-compose config
            errors=$((errors + 1))
        fi
    else
        echo -e "${RED}  ✗ docker-compose.yml not found${NC}"
        errors=$((errors + 1))
    fi

    # Check .env file
    echo -e "${YELLOW}Checking .env file...${NC}"
    if [ -f ".env" ]; then
        echo -e "${GREEN}  ✓ .env file exists${NC}"

        # Check required variables
        local required_vars=("MYSQL_ROOT_PASSWORD" "SLAPD_PASSWORD" "LDAP_ADMIN_PASSWORD")
        for var in "${required_vars[@]}"; do
            if grep -q "^${var}=" .env; then
                echo -e "${GREEN}    ✓ ${var} is set${NC}"
            else
                echo -e "${RED}    ✗ ${var} is not set${NC}"
                errors=$((errors + 1))
            fi
        done
    else
        echo -e "${RED}  ✗ .env file not found${NC}"
        errors=$((errors + 1))
    fi

    # Check scripts
    echo -e "${YELLOW}Checking setup scripts...${NC}"
    local scripts=("setup/run.sh" "setup/update-os.sh" "setup/update-virtualmin.sh"
                   "setup/backup-container.sh" "setup/restore-container.sh")
    for script in "${scripts[@]}"; do
        if [ -f "$script" ]; then
            if bash -n "$script" 2>/dev/null; then
                echo -e "${GREEN}  ✓ $script is valid${NC}"
            else
                echo -e "${RED}  ✗ $script has syntax errors${NC}"
                errors=$((errors + 1))
            fi
        else
            echo -e "${RED}  ✗ $script not found${NC}"
            errors=$((errors + 1))
        fi
    done

    # Summary
    echo ""
    if [ $errors -eq 0 ]; then
        echo -e "${GREEN}✓ All configurations are valid${NC}"
    else
        echo -e "${RED}✗ Found $errors configuration error(s)${NC}"
        exit 1
    fi
}

# Main script logic
show_header

case "${1:-help}" in
    build)
        check_prerequisites
        build_image "$@"
        ;;
    test)
        check_prerequisites
        run_tests "$@"
        ;;
    install)
        install_container "$@"
        ;;
    debug)
        debug_container "$@"
        ;;
    publish)
        check_prerequisites
        publish_image "$@"
        ;;
    clean|cleanup)
        cleanup "$@"
        ;;
    status)
        show_status
        ;;
    logs)
        show_logs "$@"
        ;;
    shell|bash|sh)
        open_shell
        ;;
    backup)
        backup_container "$@"
        ;;
    restore)
        restore_container "$@"
        ;;
    update)
        update_container
        ;;
    version)
        manage_version "$@"
        ;;
    validate)
        validate_config
        ;;
    monitor|monitoring)
        show_monitoring
        ;;
    metrics)
        show_metrics
        ;;
    help|--help|-h)
        show_usage
        ;;
    *)
        echo -e "${RED}Unknown command: $1${NC}"
        show_usage
        exit 1
        ;;
esac

exit 0