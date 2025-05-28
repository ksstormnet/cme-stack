#!/bin/bash

# File: scripts/cleanup-monitoring-config.sh
# CME Stack - Cleanup Monitoring Configuration
# Removes unnecessary service directories and updates monitoring configs

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Simple path resolution - assume running from project root
PROJECT_ROOT="$(pwd)"

echo -e "${BLUE}🧹 CME Stack Monitoring Configuration Cleanup${NC}"
echo -e "${BLUE}=============================================${NC}"
echo
echo -e "${BLUE}Working directory: $PROJECT_ROOT${NC}"
echo

# Function to remove unnecessary service directories
cleanup_service_directories() {
    echo -e "${YELLOW}📁 Cleaning up unnecessary service directories...${NC}"
    
    local services_to_remove=("alertmanager" "loki" "promtail" "prometheus" "redis-commander")
    
    for service in "${services_to_remove[@]}"; do
        local service_dir="$PROJECT_ROOT/services/$service"
        if [[ -d "$service_dir" ]]; then
            echo "  Removing: services/$service/"
            rm -rf "$service_dir"
            echo -e "  ${GREEN}✅ Removed services/$service/${NC}"
        else
            echo -e "  ${BLUE}ℹ️  services/$service/ doesn't exist (already clean)${NC}"
        fi
    done
    
    echo
}

# Function to update monitoring configuration files
update_monitoring_configs() {
    echo -e "${YELLOW}⚙️  Updating monitoring configuration files...${NC}"
    
    # Ensure monitoring directories exist
    echo "  Creating monitoring directories if needed..."
    mkdir -p "$PROJECT_ROOT/monitoring/prometheus/rules"
    mkdir -p "$PROJECT_ROOT/monitoring/prometheus/targets"
    mkdir -p "$PROJECT_ROOT/monitoring/grafana/provisioning/dashboards"
    mkdir -p "$PROJECT_ROOT/monitoring/grafana/provisioning/datasources"
    mkdir -p "$PROJECT_ROOT/monitoring/grafana/dashboards"
    mkdir -p "$PROJECT_ROOT/monitoring/loki"
    mkdir -p "$PROJECT_ROOT/monitoring/promtail"
    mkdir -p "$PROJECT_ROOT/monitoring/alertmanager"
    
    # Update Prometheus configuration
    echo "  Updating prometheus.yml..."
    cat > "$PROJECT_ROOT/monitoring/prometheus/prometheus.yml" << 'EOF'
# File: monitoring/prometheus/prometheus.yml
# Prometheus configuration for CME Stack development environment

global:
  scrape_interval: 15s
  evaluation_interval: 15s

rule_files:
  - "rules/*.yml"

alerting:
  alertmanagers:
    - static_configs:
        - targets:
          - dev-alertmanager:9093

scrape_configs:
  # Prometheus itself
  - job_name: 'prometheus'
    static_configs:
      - targets: ['localhost:9090']

  # Node Exporter (system metrics)
  - job_name: 'node-exporter'
    static_configs:
      - targets: ['dev-node-exporter:9100']
    scrape_interval: 30s

  # cAdvisor (container metrics)
  - job_name: 'cadvisor'
    static_configs:
      - targets: ['dev-cadvisor:8080']
    scrape_interval: 30s

  # WordPress metrics (if available)
  - job_name: 'wordpress'
    static_configs:
      - targets: ['dev-wordpress:80']
    metrics_path: '/metrics'
    scrape_interval: 60s
    scrape_timeout: 10s

  # n8n metrics
  - job_name: 'n8n'
    static_configs:
      - targets: ['dev-n8n:5678']
    metrics_path: '/metrics'
    scrape_interval: 30s

  # GitLab metrics (if enabled)
  - job_name: 'gitlab'
    static_configs:
      - targets: ['dev-gitlab:80']
    metrics_path: '/-/metrics'
    scrape_interval: 60s
    scrape_timeout: 15s

  # GlitchTip metrics (if available)
  - job_name: 'glitchtip'
    static_configs:
      - targets: ['dev-glitchtip-web:8000']
    metrics_path: '/metrics'
    scrape_interval: 60s
EOF
    echo -e "  ${GREEN}✅ Updated prometheus.yml${NC}"

    # Update Loki configuration
    echo "  Updating loki-config.yml..."
    cat > "$PROJECT_ROOT/monitoring/loki/loki-config.yml" << 'EOF'
# File: monitoring/loki/loki-config.yml
# Loki configuration for CME Stack development environment

auth_enabled: false

server:
  http_listen_port: 3100
  grpc_listen_port: 9096

common:
  path_prefix: /loki
  storage:
    filesystem:
      chunks_directory: /loki/chunks
      rules_directory: /loki/rules
  replication_factor: 1
  ring:
    instance_addr: 127.0.0.1
    kvstore:
      store: inmemory

query_scheduler:
  max_outstanding_requests_per_tenant: 32768

schema_config:
  configs:
    - from: 2020-10-24
      store: boltdb-shipper
      object_store: filesystem
      schema: v11
      index:
        prefix: index_
        period: 24h

ruler:
  alertmanager_url: http://dev-alertmanager:9093

# Retention (30 days for development)
limits_config:
  retention_period: 720h
  ingestion_rate_mb: 4
  ingestion_burst_size_mb: 6
  max_concurrent_tail_requests: 10

# Development optimizations
analytics:
  reporting_enabled: false
EOF
    echo -e "  ${GREEN}✅ Updated loki-config.yml${NC}"

    # Update Promtail configuration
    echo "  Updating promtail-config.yml..."
    cat > "$PROJECT_ROOT/monitoring/promtail/promtail-config.yml" << 'EOF'
# File: monitoring/promtail/promtail-config.yml
# Promtail configuration for CME Stack development environment

server:
  http_listen_port: 9080
  grpc_listen_port: 0

positions:
  filename: /tmp/positions.yaml

clients:
  - url: http://dev-loki:3100/loki/api/v1/push

scrape_configs:
  # Docker container logs
  - job_name: containers
    static_configs:
      - targets:
          - localhost
        labels:
          job: containerlogs
          __path__: /var/lib/docker/containers/*/*log

    pipeline_stages:
      - json:
          expressions:
            output: log
            stream: stream
            attrs:
      - json:
          expressions:
            tag:
          source: attrs
      - regex:
          expression: (?P<container_name>(?:[^|])*[^|])
          source: tag
      - timestamp:
          format: RFC3339Nano
          source: time
      - labels:
          stream:
          container_name:
      - output:
          source: output

  # WordPress logs
  - job_name: wordpress
    static_configs:
      - targets:
          - localhost
        labels:
          job: wordpress
          service: wordpress
          __path__: /var/log/wordpress/*.log

  # Matomo logs  
  - job_name: matomo
    static_configs:
      - targets:
          - localhost
        labels:
          job: matomo
          service: matomo
          __path__: /var/www/html/tmp/logs/*.log

  # n8n logs
  - job_name: n8n
    static_configs:
      - targets:
          - localhost
        labels:
          job: n8n
          service: n8n
          __path__: /var/log/n8n/*.log

  # GitLab logs
  - job_name: gitlab
    static_configs:
      - targets:
          - localhost
        labels:
          job: gitlab
          service: gitlab
          __path__: /var/log/gitlab/**/*.log
EOF
    echo -e "  ${GREEN}✅ Updated promtail-config.yml${NC}"

    # Update AlertManager configuration
    echo "  Updating alertmanager.yml..."
    cat > "$PROJECT_ROOT/monitoring/alertmanager/alertmanager.yml" << 'EOF'
# File: monitoring/alertmanager/alertmanager.yml
# AlertManager configuration for CME Stack development environment

global:
  smtp_smarthost: 'localhost:587'
  smtp_from: 'alerts@cruisemadeeasy.dev'

route:
  group_by: ['alertname']
  group_wait: 10s
  group_interval: 10s
  repeat_interval: 1h
  receiver: 'web.hook'

receivers:
  - name: 'web.hook'
    email_configs:
      - to: 'admin@cruisemadeeasy.dev'
        subject: 'CME Stack Alert: {{ .GroupLabels.alertname }}'
        body: |
          {{ range .Alerts }}
          Alert: {{ .Annotations.summary }}
          Description: {{ .Annotations.description }}
          {{ end }}

inhibit_rules:
  - source_match:
      severity: 'critical'
    target_match:
      severity: 'warning'
    equal: ['alertname', 'dev', 'instance']
EOF
    echo -e "  ${GREEN}✅ Updated alertmanager.yml${NC}"

    echo
}

# Function to update generate-dev-secrets.sh
update_secrets_script() {
    echo -e "${YELLOW}🔑 Updating generate-dev-secrets.sh script...${NC}"
    
    local secrets_script="$PROJECT_ROOT/scripts/generate-dev-secrets.sh"
    
    # Create backup of existing script
    if [[ -f "$secrets_script" ]]; then
        echo "  Backing up existing generate-dev-secrets.sh..."
        cp "$secrets_script" "$secrets_script.backup-$(date +%Y%m%d-%H%M%S)"
    fi
    
    # Create updated secrets script
    echo "  Writing new generate-dev-secrets.sh..."
    cat > "$secrets_script.new" << 'EOF'
#!/bin/bash

# File: scripts/generate-dev-secrets.sh
# CME Stack Development Secrets Generator - Corrected Service List
# Generates secure credentials for business services only (monitoring uses file configs)
# 
# Usage: ./scripts/generate-dev-secrets.sh

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
SERVICES_DIR="$PROJECT_ROOT/services"

# Default database and Redis hosts
DEFAULT_DB_HOST="mariadb.local"
DEFAULT_REDIS_HOST="redis.local"

echo -e "${BLUE}🔐 CME Stack Development Secrets Generator${NC}"
echo -e "${BLUE}==========================================${NC}"
echo

# Function to generate secure random string
generate_password() {
    local length=${1:-32}
    openssl rand -base64 $length | tr -d "=+/" | cut -c1-$length
}

# Function to generate WordPress salt
generate_wp_salt() {
    openssl rand -base64 64 | tr -d "=+/" | cut -c1-64
}

# Function to prompt for configuration
prompt_config() {
    echo -e "${YELLOW}📋 Configuration Setup${NC}"
    echo "Enter your external service details (or press Enter for defaults):"
    echo
    
    read -p "MariaDB Host [$DEFAULT_DB_HOST]: " DB_HOST
    DB_HOST=${DB_HOST:-$DEFAULT_DB_HOST}
    
    read -p "Redis Host [$DEFAULT_REDIS_HOST]: " REDIS_HOST
    REDIS_HOST=${REDIS_HOST:-$DEFAULT_REDIS_HOST}
    
    read -p "Redis Password (leave empty if no auth): " REDIS_PASSWORD
    
    read -p "SMTP Host (for email notifications): " SMTP_HOST
    read -p "SMTP User: " SMTP_USER
    read -s -p "SMTP Password: " SMTP_PASSWORD
    echo
    
    # API Keys (optional)
    echo
    echo "External API Keys (optional - press Enter to skip):"
    read -p "OpenAI API Key: " OPENAI_API_KEY
    read -p "GoHighLevel API Key: " GHL_API_KEY
    read -p "GoHighLevel Location ID: " GHL_LOCATION_ID
    read -p "Voip.ms API Key: " VOIPMS_API_KEY
    
    echo -e "${GREEN}✅ Configuration complete${NC}"
    echo
}

# Function to generate service credentials
generate_service_secrets() {
    local service=$1
    local template_file="$SERVICES_DIR/$service/.env.template"
    local env_file="$SERVICES_DIR/$service/.env"
    
    if [[ ! -f "$template_file" ]]; then
        echo -e "${RED}❌ Template not found: $template_file${NC}"
        return 1
    fi
    
    echo -e "${BLUE}🔑 Generating secrets for $service...${NC}"
    
    # Create service directory if it doesn't exist
    mkdir -p "$SERVICES_DIR/$service"
    
    # Copy template to .env file
    cp "$template_file" "$env_file"
    
    # Generate service-specific passwords
    local db_password=$(generate_password 32)
    local admin_password=$(generate_password 16)
    
    # Replace common placeholders first
    sed -i.bak \
        -e "s/your-mariadb-host/$DB_HOST/g" \
        -e "s/your-redis-host/$REDIS_HOST/g" \
        -e "s/your-redis-password/$REDIS_PASSWORD/g" \
        -e "s/your-smtp-host/$SMTP_HOST/g" \
        -e "s/your-smtp-user/$SMTP_USER/g" \
        -e "s/your-smtp-password/$SMTP_PASSWORD/g" \
        -e "s/your-openai-api-key/$OPENAI_API_KEY/g" \
        -e "s/your-ghl-api-key/$GHL_API_KEY/g" \
        -e "s/your-ghl-location-id/$GHL_LOCATION_ID/g" \
        -e "s/your-voipms-api-key/$VOIPMS_API_KEY/g" \
        -e "s/GENERATED_PASSWORD_32_CHARS/$db_password/g" \
        -e "s/GENERATED_ADMIN_PASSWORD/$admin_password/g" \
        "$env_file"
    
    # Service-specific replacements
    case $service in
        "wordpress")
            local auth_key=$(generate_wp_salt)
            local secure_auth_key=$(generate_wp_salt)
            local logged_in_key=$(generate_wp_salt)
            local nonce_key=$(generate_wp_salt)
            local auth_salt=$(generate_wp_salt)
            local secure_auth_salt=$(generate_wp_salt)
            local logged_in_salt=$(generate_wp_salt)
            local nonce_salt=$(generate_wp_salt)
            local cache_purge_key=$(generate_password 32)
            local matomo_token=$(generate_password 32)
            
            sed -i.bak2 \
                -e "s/GENERATED_64_CHAR_SECRET/$auth_key/g" \
                -e "s/WP_SECURE_AUTH_KEY=.*/WP_SECURE_AUTH_KEY=$secure_auth_key/g" \
                -e "s/WP_LOGGED_IN_KEY=.*/WP_LOGGED_IN_KEY=$logged_in_key/g" \
                -e "s/WP_NONCE_KEY=.*/WP_NONCE_KEY=$nonce_key/g" \
                -e "s/WP_AUTH_SALT=.*/WP_AUTH_SALT=$auth_salt/g" \
                -e "s/WP_SECURE_AUTH_SALT=.*/WP_SECURE_AUTH_SALT=$secure_auth_salt/g" \
                -e "s/WP_LOGGED_IN_SALT=.*/WP_LOGGED_IN_SALT=$logged_in_salt/g" \
                -e "s/WP_NONCE_SALT=.*/WP_NONCE_SALT=$nonce_salt/g" \
                -e "s/GENERATED_32_CHAR_SALT/$cache_purge_key/g" \
                "$env_file"
            # Second pass for remaining WordPress-specific tokens
            sed -i.bak3 \
                -e "s/GENERATED_32_CHAR_SALT/$matomo_token/g" \
                "$env_file"
            rm -f "$env_file.bak2" "$env_file.bak3"
            ;;
        "n8n")
            local encryption_key=$(generate_password 64)
            sed -i.bak2 \
                -e "s/GENERATED_64_CHAR_ENCRYPTION_KEY/$encryption_key/g" \
                "$env_file"
            rm -f "$env_file.bak2"
            ;;
        "matomo")
            local api_token=$(generate_password 32)
            sed -i.bak2 \
                -e "s/GENERATED_32_CHAR_SALT/$api_token/g" \
                "$env_file"
            rm -f "$env_file.bak2"
            ;;
        "glitchtip")
            local secret_key=$(generate_password 64)
            sed -i.bak2 \
                -e "s/GENERATED_64_CHAR_SECRET_KEY/$secret_key/g" \
                "$env_file"
            rm -f "$env_file.bak2"
            ;;
        "gitlab")
            local root_password=$(generate_password 20)
            sed -i.bak2 \
                -e "s/GENERATED_ROOT_PASSWORD/$root_password/g" \
                "$env_file"
            rm -f "$env_file.bak2"
            ;;
        "grafana")
            local secret_key=$(generate_password 64)
            sed -i.bak2 \
                -e "s/GENERATED_64_CHAR_SECRET/$secret_key/g" \
                "$env_file"
            rm -f "$env_file.bak2"
            ;;
        *)
            # Generic replacements for other services
            sed -i.bak2 \
                -e "s/GENERATED_64_CHAR_SECRET/$(generate_password 64)/g" \
                -e "s/GENERATED_64_CHAR_SECRET_KEY/$(generate_password 64)/g" \
                -e "s/GENERATED_32_CHAR_SALT/$(generate_password 32)/g" \
                "$env_file"
            rm -f "$env_file.bak2"
            ;;
    esac
    
    # Remove backup file
    rm -f "$env_file.bak"
    
    # Store credentials for SQL generation and display
    SERVICE_CREDENTIALS[$service]="$db_password"
    ADMIN_PASSWORDS[$service]="$admin_password"
    
    echo -e "${GREEN}✅ Generated $service secrets${NC}"
}

# Function to generate SQL commands
generate_sql_commands() {
    echo -e "${YELLOW}📊 Database Setup Commands${NC}"
    echo -e "${YELLOW}=========================${NC}"
    echo
    echo "-- Run these commands on your MariaDB server ($DB_HOST):"
    echo
    
    # Only services that need databases
    for service in wordpress matomo n8n glitchtip gitlab grafana; do
        if [[ -n "${SERVICE_CREDENTIALS[$service]:-}" ]]; then
            local password="${SERVICE_CREDENTIALS[$service]}"
            echo "-- $service database and user"
            echo "CREATE DATABASE IF NOT EXISTS cme_dev_$service CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"
            echo "CREATE USER IF NOT EXISTS 'cme_dev_${service}_user'@'%' IDENTIFIED BY '$password';"
            echo "GRANT ALL PRIVILEGES ON cme_dev_$service.* TO 'cme_dev_${service}_user'@'%';"
            echo
        fi
    done
    
    echo "FLUSH PRIVILEGES;"
    echo
    echo -e "${GREEN}✅ Database commands generated${NC}"
}

# Function to display admin credentials
display_admin_credentials() {
    echo -e "${YELLOW}🔑 Admin Credentials${NC}"
    echo -e "${YELLOW}==================${NC}"
    echo
    echo "Save these admin credentials securely:"
    echo
    
    for service in wordpress matomo n8n glitchtip gitlab grafana; do
        if [[ -n "${ADMIN_PASSWORDS[$service]:-}" ]]; then
            local password="${ADMIN_PASSWORDS[$service]}"
            case $service in
                "gitlab")
                    echo -e "$service: ${GREEN}root${NC} / ${GREEN}$password${NC}"
                    ;;
                *)
                    echo -e "$service: ${GREEN}admin${NC} / ${GREEN}$password${NC}"
                    ;;
            esac
        fi
    done
    
    echo
    echo -e "${BLUE}💡 Service URLs (development):${NC}"
    echo "WordPress:   https://dev-wordpress.cme.ksstorm.dev"
    echo "Matomo:      https://dev-matomo.cme.ksstorm.dev"
    echo "n8n:         https://dev-n8n.cme.ksstorm.dev"
    echo "GlitchTip:   https://dev-glitchtip.cme.ksstorm.dev"
    echo "GitLab:      https://dev-gitlab.cme.ksstorm.dev"
    echo "Grafana:     https://dev-grafana.cme.ksstorm.dev"
    echo
    echo -e "${BLUE}💡 Monitoring (file-configured):${NC}"
    echo "Prometheus:  https://dev-prometheus.cme.ksstorm.dev"
    echo "AlertManager: https://dev-alertmanager.cme.ksstorm.dev"
    echo
}

# Function to check prerequisites
check_prerequisites() {
    echo -e "${BLUE}🔍 Checking prerequisites...${NC}"
    
    # Check for required commands
    local missing=()
    
    if ! command -v openssl &> /dev/null; then
        missing+=("openssl")
    fi
    
    if [[ ${#missing[@]} -gt 0 ]]; then
        echo -e "${RED}❌ Missing required tools: ${missing[*]}${NC}"
        echo "Please install the missing tools and try again."
        exit 1
    fi
    
    # Check if templates exist - only business services need them
    local templates_missing=()
    local services=("wordpress" "matomo" "n8n" "glitchtip" "gitlab" "grafana")
    
    for service in "${services[@]}"; do
        if [[ ! -f "$SERVICES_DIR/$service/.env.template" ]]; then
            templates_missing+=("$service")
        fi
    done
    
    if [[ ${#templates_missing[@]} -gt 0 ]]; then
        echo -e "${RED}❌ Missing .env.template files for: ${templates_missing[*]}${NC}"
        echo "Please ensure all template files are present in services/ directories."
        exit 1
    fi
    
    echo -e "${GREEN}✅ Prerequisites check passed${NC}"
    echo
}

# Function to backup existing .env files
backup_existing_env() {
    echo -e "${BLUE}💾 Backing up existing .env files...${NC}"
    
    local backup_dir="$PROJECT_ROOT/temp-secrets/backup-$(date +%Y%m%d-%H%M%S)"
    local found_existing=false
    
    for service_dir in "$SERVICES_DIR"/*; do
        if [[ -d "$service_dir" && -f "$service_dir/.env" ]]; then
            if [[ "$found_existing" == false ]]; then
                mkdir -p "$backup_dir"
                found_existing=true
            fi
            
            local service=$(basename "$service_dir")
            cp "$service_dir/.env" "$backup_dir/$service.env"
            echo "  Backed up: $service"
        fi
    done
    
    if [[ "$found_existing" == true ]]; then
        echo -e "${GREEN}✅ Existing .env files backed up to: $backup_dir${NC}"
    else
        echo -e "${BLUE}ℹ️  No existing .env files found${NC}"
    fi
    echo
}

# Function to show next steps
show_next_steps() {
    echo -e "${YELLOW}🚀 Next Steps${NC}"
    echo -e "${YELLOW}============${NC}"
    echo
    echo "1. Run the database setup commands shown above on your MariaDB server"
    echo "2. Start the development environment:"
    echo "   ${GREEN}docker-compose -f docker-compose.dev.yml up -d${NC}"
    echo
    echo "3. Or use individual service groups:"
    echo "   ${GREEN}docker-compose -f docker-compose.frontend.yml up -d${NC}     # Core services"
    echo "   ${GREEN}docker-compose -f docker-compose.infrastructure.yml up -d${NC} # GitLab, GlitchTip"
    echo "   ${GREEN}docker-compose -f docker-compose.monitoring.yml up -d${NC}     # Monitoring stack"
    echo
    echo "4. Access services using the URLs and credentials listed above"
    echo
    echo -e "${BLUE}💡 Tips:${NC}"
    echo "- All .env files are ignored by git (never committed)"
    echo "- Re-run this script anytime to regenerate credentials"
    echo "- Backup files are kept in temp-secrets/ for recovery"
    echo "- Monitoring services use file-based config in monitoring/ directory"
    echo
    echo -e "${GREEN}✅ Development secrets setup complete!${NC}"
}

# Main execution
main() {
    # Check if running from correct directory
    if [[ ! -f "$PROJECT_ROOT/docker-compose.dev.yml" ]]; then
        echo -e "${RED}❌ Please run this script from the CME project root directory${NC}"
        exit 1
    fi
    
    # Initialize arrays for storing credentials
    declare -A SERVICE_CREDENTIALS
    declare -A ADMIN_PASSWORDS
    
    # Run setup steps
    check_prerequisites
    backup_existing_env
    prompt_config
    
    echo -e "${BLUE}🔐 Generating secrets for business services only...${NC}"
    echo -e "${BLUE}ℹ️  Monitoring services use file-based configuration${NC}"
    echo
    
    # Generate secrets for business services only
    local services=("wordpress" "matomo" "n8n" "glitchtip" "gitlab" "grafana")
    
    for service in "${services[@]}"; do
        if [[ -f "$SERVICES_DIR/$service/.env.template" ]]; then
            generate_service_secrets "$service"
        else
            echo -e "${YELLOW}⚠️  Skipping $service (no template found)${NC}"
        fi
    done
    
    echo
    generate_sql_commands
    echo
    display_admin_credentials
    echo
    show_next_steps
}

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
EOF

    # Replace the original file
    mv "$secrets_script.new" "$secrets_script"
    chmod +x "$secrets_script"
    echo -e "  ${GREEN}✅ Updated generate-dev-secrets.sh${NC}"
    echo
}

# Function to show summary
show_summary() {
    echo -e "${GREEN}🎉 Cleanup Complete!${NC}"
    echo -e "${GREEN}==================${NC}"
    echo
    echo "Changes made:"
    echo "✅ Removed unnecessary service directories (alertmanager, loki, promtail, prometheus, redis-commander)"
    echo "✅ Updated monitoring configuration files with proper settings"
    echo "✅ Updated generate-dev-secrets.sh to handle only business services"
    echo
    echo "Current service structure:"
    echo "📁 Business services (need .env files):"
    echo "   - services/wordpress/"
    echo "   - services/matomo/"
    echo "   - services/n8n/"
    echo "   - services/glitchtip/"
    echo "   - services/gitlab/"
    echo "   - services/grafana/"
    echo
    echo "📁 Monitoring services (use file configs):"
    echo "   - monitoring/prometheus/prometheus.yml"
    echo "   - monitoring/grafana/provisioning/"
    echo "   - monitoring/loki/loki-config.yml" 
    echo "   - monitoring/promtail/promtail-config.yml"
    echo "   - monitoring/alertmanager/alertmanager.yml"
    echo
    echo "Next steps:"
    echo "1. Run: ./scripts/generate-dev-secrets.sh"
    echo "2. Test: docker-compose -f docker-compose.dev.yml config"
    echo "3. Start: docker-compose -f docker-compose.dev.yml up -d"
    echo
}

# Main execution
main() {
    cleanup_service_directories
    update_monitoring_configs
    update_secrets_script
    show_summary
}

# Run if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi