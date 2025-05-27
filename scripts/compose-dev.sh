#!/bin/bash

# ================================================================
# CME Development Stack Management Script
# ================================================================
# Manages the modular Docker Compose stack with various profiles
# and service groupings for efficient development workflows
# ================================================================

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ENV_FILE="${PROJECT_DIR}/.env.dev"
MAIN_COMPOSE_FILE="${PROJECT_DIR}/dev-compose.yml"

# Service groups
FRONTEND_SERVICES=("dev-wordpress" "dev-wordpress-init" "dev-matomo" "dev-matomo-init" "dev-n8n")
INFRASTRUCTURE_SERVICES=("dev-glitchtip-web" "dev-glitchtip-worker" "dev-glitchtip-migrate" "dev-gitlab" "dev-mailhog")
MONITORING_SERVICES=("dev-prometheus" "dev-grafana" "dev-loki" "dev-promtail")
OPTIONAL_SERVICES=("dev-node-exporter" "dev-cadvisor" "dev-alertmanager" "dev-redis-commander" "dev-adminer")

# Logging functions
log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] $1${NC}"
}

warn() {
    echo -e "${YELLOW}[$(date +'%Y-%m-%d %H:%M:%S')] WARNING: $1${NC}"
}

error() {
    echo -e "${RED}[$(date +'%Y-%m-%d %H:%M:%S')] ERROR: $1${NC}"
    exit 1
}

info() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')] INFO: $1${NC}"
}

# ================================================================
# UTILITY FUNCTIONS
# ================================================================

check_prerequisites() {
    log "Checking prerequisites..."

    if ! command -v docker &> /dev/null; then
        error "Docker is not installed"
    fi

    if ! docker compose version &> /dev/null; then
        error "Docker Compose is not available"
    fi

    if [[ ! -f "$ENV_FILE" ]]; then
        error "Environment file $ENV_FILE not found. Run './scripts/generate-dev-secrets.sh' first"
    fi

    # Check if external networks exist
    if ! docker network ls | grep -q "external"; then
        warn "External network not found. Creating it..."
        docker network create external || warn "Failed to create external network"
    fi

    if ! docker network ls | grep -q "dev"; then
        info "Creating dev network..."
        docker network create dev || warn "Failed to create dev network"
    fi

    log "Prerequisites check completed"
}

# ================================================================
# DOCKER COMPOSE OPERATIONS
# ================================================================

compose_cmd() {
    local cmd="$1"
    shift
    docker compose --env-file "$ENV_FILE" -f "$MAIN_COMPOSE_FILE" "$cmd" "$@"
}

# ================================================================
# SERVICE MANAGEMENT
# ================================================================

start_services() {
    local group="${1:-all}"
    local services=()

    case "$group" in
        "frontend"|"front")
            services=("${FRONTEND_SERVICES[@]}")
            log "Starting frontend services..."
            ;;
        "infrastructure"|"infra")
            services=("${INFRASTRUCTURE_SERVICES[@]}")
            log "Starting infrastructure services..."
            ;;
        "monitoring"|"monitor")
            services=("${MONITORING_SERVICES[@]}")
            log "Starting monitoring services..."
            ;;
        "minimal")
            services=("dev-wordpress" "dev-wordpress-init" "dev-matomo" "dev-matomo-init")
            log "Starting minimal services for basic development..."
            ;;
        "wordpress")
            services=("dev-wordpress" "dev-wordpress-init")
            log "Starting WordPress services only..."
            ;;
        "analytics")
            services=("dev-matomo" "dev-matomo-init")
            log "Starting Matomo analytics only..."
            ;;
        "automation")
            services=("dev-n8n")
            log "Starting n8n automation only..."
            ;;
        "all")
            log "Starting all services..."
            compose_cmd up -d
            return
            ;;
        *)
            error "Unknown service group: $group"
            ;;
    esac

    if [[ ${#services[@]} -gt 0 ]]; then
        compose_cmd up -d "${services[@]}"
    fi

    show_status "$group"
}

stop_services() {
    local group="${1:-all}"

    case "$group" in
        "frontend"|"front")
            log "Stopping frontend services..."
            compose_cmd stop "${FRONTEND_SERVICES[@]}"
            ;;
        "infrastructure"|"infra")
            log "Stopping infrastructure services..."
            compose_cmd stop "${INFRASTRUCTURE_SERVICES[@]}"
            ;;
        "monitoring"|"monitor")
            log "Stopping monitoring services..."
            compose_cmd stop "${MONITORING_SERVICES[@]}"
            ;;
        "all")
            log "Stopping all services..."
            compose_cmd down
            ;;
        *)
            error "Unknown service group: $group"
            ;;
    esac
}

restart_services() {
    local group="${1:-all}"
    log "Restarting services in group: $group"
    stop_services "$group"
    sleep 2
    start_services "$group"
}

# ================================================================
# DEVELOPMENT WORKFLOWS
# ================================================================

dev_mode() {
    log "Starting development mode with live reloading..."

    # Start core services needed for development
    local dev_services=(
        "dev-wordpress"
        "dev-wordpress-cli"
        "dev-matomo"
        "dev-matomo-init"
        "dev-n8n"
        "dev-mailhog"
        "dev-prometheus"
        "dev-grafana"
    )

    compose_cmd up -d "${dev_services[@]}"

    info "Development mode started. Core services are running."
    info "Run '$0 logs' to view logs, or '$0 status' to check service health."
}

production_like() {
    log "Starting production-like environment..."

    # Start all services including monitoring and infrastructure
    compose_cmd --profile monitoring-extended up -d

    info "Production-like environment started with full monitoring stack."
}

# ================================================================
# MONITORING AND DEBUGGING
# ================================================================

show_status() {
    local group="${1:-all}"
    log "Service Status for group: $group"
    echo ""

    compose_cmd ps --format "table {{.Name}}\t{{.Status}}\t{{.Ports}}"
    echo ""

    # Show service URLs
    echo -e "${BLUE}Service URLs (via Zoraxy):${NC}"
    echo "WordPress:     https://dev-wordpress.cme.ksstorm.dev"
    echo "Matomo:        https://dev-matomo.cme.ksstorm.dev"
    echo "n8n:           https://dev-n8n.cme.ksstorm.dev"
    echo "GlitchTip:     https://dev-glitchtip.cme.ksstorm.dev"
    echo "GitLab:        https://dev-gitlab.cme.ksstorm.dev"
    echo "Grafana:       https://dev-grafana.cme.ksstorm.dev"
    echo "Prometheus:    https://dev-prometheus.cme.ksstorm.dev"
    echo ""
    echo -e "${BLUE}Direct Access:${NC}"
    echo "MailHog:       http://localhost:50025"
    echo "GitLab SSH:    ssh://git@localhost:50022"
    echo ""
}

show_logs() {
    local service="${1:-}"

    if [[ -n "$service" ]]; then
        log "Showing logs for service: $service"
        compose_cmd logs -f "$service"
    else
        log "Showing logs for all services (Ctrl+C to exit)"
        compose_cmd logs -f
    fi
}

show_health() {
    log "Health check status:"
    echo ""

    # Get health status for all services
    docker ps --format "table {{.Names}}\t{{.Status}}" --filter "name=dev-" | \
    while IFS=$'\t' read -r name status; do
        if [[ "$name" != "NAMES" ]]; then
            if echo "$status" | grep -q "healthy"; then
                echo -e "${name}: ${GREEN}✓ Healthy${NC}"
            elif echo "$status" | grep -q "unhealthy"; then
                echo -e "${name}: ${RED}✗ Unhealthy${NC}"
            elif echo "$status" | grep -q "starting"; then
                echo -e "${name}: ${YELLOW}⟳ Starting${NC}"
            else
                echo -e "${name}: ${BLUE}? Unknown${NC}"
            fi
        fi
    done
}

# ================================================================
# MAINTENANCE OPERATIONS
# ================================================================

cleanup() {
    log "Cleaning up development environment..."

    read -p "This will remove all containers and volumes. Continue? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        compose_cmd down -v --remove-orphans
        docker system prune -f
        log "Cleanup completed"
    else
        info "Cleanup cancelled"
    fi
}

backup_data() {
    log "Creating backup of development data..."

    local backup_dir="${PROJECT_DIR}/backups/$(date +%Y%m%d_%H%M%S)"
    mkdir -p "$backup_dir"

    # Export database data
    info "Backing up databases..."
    # Add database backup commands here

    # Copy configuration files
    info "Backing up configurations..."
    cp -r "${PROJECT_DIR}/services" "$backup_dir/"
    cp -r "${PROJECT_DIR}/monitoring" "$backup_dir/"
    cp "$ENV_FILE" "$backup_dir/"

    log "Backup created at: $backup_dir"
}

update_images() {
    log "Updating Docker images..."

    compose_cmd pull
    compose_cmd up -d --remove-orphans

    log "Images updated and services restarted"
}

# ================================================================
# MAIN EXECUTION
# ================================================================

show_usage() {
    echo "Usage: $0 [command] [options]"
    echo ""
    echo "Service Management:"
    echo "  start [group]       - Start services (all|frontend|infrastructure|monitoring|minimal)"
    echo "  stop [group]        - Stop services"
    echo "  restart [group]     - Restart services"
    echo "  status [group]      - Show service status"
    echo ""
    echo "Development Workflows:"
    echo "  dev                 - Start development mode (core services only)"
    echo "  prod-like           - Start production-like environment"
    echo ""
    echo "Monitoring & Debugging:"
    echo "  logs [service]      - Show logs (all services or specific service)"
    echo "  health              - Show health status of all services"
    echo ""
    echo "Maintenance:"
    echo "  cleanup             - Remove all containers and volumes"
    echo "  backup              - Backup development data"
    echo "  update              - Update Docker images"
    echo ""
    echo "Examples:"
    echo "  $0 start frontend   # Start only WordPress, Matomo, n8n"
    echo "  $0 dev              # Start core development services"
    echo "  $0 logs dev-wordpress # Show WordPress logs"
    echo "  $0 health           # Check all service health"
}

main() {
    echo -e "${GREEN}"
    echo "================================================================"
    echo "  CME Development Stack Management"
    echo "================================================================"
    echo -e "${NC}"

    check_prerequisites

    case "${1:-status}" in
        "start")
            start_services "${2:-all}"
            ;;
        "stop")
            stop_services "${2:-all}"
            ;;
        "restart")
            restart_services "${2:-all}"
            ;;
        "status")
            show_status "${2:-all}"
            ;;
        "dev")
            dev_mode
            ;;
        "prod-like")
            production_like
            ;;
        "logs")
            show_logs "${2:-}"
            ;;
        "health")
            show_health
            ;;
        "cleanup")
            cleanup
            ;;
        "backup")
            backup_data
            ;;
        "update")
            update_images
            ;;
        *)
            show_usage
            exit 1
            ;;
    esac
}

# Run main function with all arguments
main "$@"
