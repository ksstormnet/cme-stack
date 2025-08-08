#!/bin/bash

# File: scripts/generate-dev-secrets.sh
# CME Stack Development Secrets Generator - Clean Rewrite
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

# Services that need .env files (business services only)
BUSINESS_SERVICES=("wordpress" "matomo" "n8n" "glitchtip" "gitlab" "grafana")

# Services that need databases
DATABASE_SERVICES=("wordpress" "matomo" "n8n" "glitchtip" "gitlab" "grafana")

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
    echo "Enter your external service details:"
    echo

    read -p "MariaDB Host [mariadb.local]: " DB_HOST
    DB_HOST=${DB_HOST:-mariadb.local}

    read -p "Redis Host [redis.local]: " REDIS_HOST
    REDIS_HOST=${REDIS_HOST:-redis.local}

    read -p "Redis Password (leave empty if no auth): " REDIS_PASSWORD

    echo
    echo "For development, email will be handled by MailHog (no SMTP config needed)"
    echo "All emails will be captured at: http://localhost:50025"
    echo

    # Set MailHog defaults for development
    SMTP_HOST="dev-mailhog"
    SMTP_PORT="1025"
    SMTP_USER=""
    SMTP_PASSWORD=""

    # API Keys (optional)
    echo "External API Keys (optional - press Enter to skip):"
    read -p "OpenAI API Key: " OPENAI_API_KEY
    read -p "GoHighLevel API Key: " GHL_API_KEY
    read -p "GoHighLevel Location ID: " GHL_LOCATION_ID
    read -p "Voip.ms API Key: " VOIPMS_API_KEY

    echo -e "${GREEN}✅ Configuration complete${NC}"
    echo
}

# Function to replace placeholders in file using envsubst-like approach
replace_in_file() {
    local file="$1"
    local find="$2"
    local replace="$3"

    # Use perl for more reliable substitution
    perl -i -pe "s/\Q$find\E/$replace/g" "$file"
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

    # Replace common placeholders using perl (more reliable than sed)
    replace_in_file "$env_file" "your-mariadb-host" "$DB_HOST"
    replace_in_file "$env_file" "your-redis-host" "$REDIS_HOST"
    replace_in_file "$env_file" "your-redis-password" "$REDIS_PASSWORD"
    replace_in_file "$env_file" "your-smtp-host" "$SMTP_HOST"
    replace_in_file "$env_file" "your-smtp-user" "$SMTP_USER"
    replace_in_file "$env_file" "your-smtp-password" "$SMTP_PASSWORD"
    replace_in_file "$env_file" "your-openai-api-key" "$OPENAI_API_KEY"
    replace_in_file "$env_file" "your-ghl-api-key" "$GHL_API_KEY"
    replace_in_file "$env_file" "your-ghl-location-id" "$GHL_LOCATION_ID"
    replace_in_file "$env_file" "your-voipms-api-key" "$VOIPMS_API_KEY"
    replace_in_file "$env_file" "GENERATED_PASSWORD_32_CHARS" "$db_password"
    replace_in_file "$env_file" "GENERATED_ADMIN_PASSWORD" "$admin_password"

    # Service-specific replacements using perl (more reliable)
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

            # Replace WordPress-specific tokens
            replace_in_file "$env_file" "GENERATED_64_CHAR_SECRET" "$auth_key"

            # Handle WordPress keys with exact line replacement
            perl -i -pe "s/^WP_SECURE_AUTH_KEY=.*/WP_SECURE_AUTH_KEY=$secure_auth_key/" "$env_file"
            perl -i -pe "s/^WP_LOGGED_IN_KEY=.*/WP_LOGGED_IN_KEY=$logged_in_key/" "$env_file"
            perl -i -pe "s/^WP_NONCE_KEY=.*/WP_NONCE_KEY=$nonce_key/" "$env_file"
            perl -i -pe "s/^WP_AUTH_SALT=.*/WP_AUTH_SALT=$auth_salt/" "$env_file"
            perl -i -pe "s/^WP_SECURE_AUTH_SALT=.*/WP_SECURE_AUTH_SALT=$secure_auth_salt/" "$env_file"
            perl -i -pe "s/^WP_LOGGED_IN_SALT=.*/WP_LOGGED_IN_SALT=$logged_in_salt/" "$env_file"
            perl -i -pe "s/^WP_NONCE_SALT=.*/WP_NONCE_SALT=$nonce_salt/" "$env_file"

            # Handle GENERATED_32_CHAR_SALT - first occurrence gets cache key
            replace_in_file "$env_file" "GENERATED_32_CHAR_SALT" "$cache_purge_key"
            # Second occurrence gets matomo token
            replace_in_file "$env_file" "GENERATED_32_CHAR_SALT" "$matomo_token"
            ;;
        "n8n")
            local encryption_key=$(generate_password 64)
            replace_in_file "$env_file" "GENERATED_64_CHAR_ENCRYPTION_KEY" "$encryption_key"
            ;;
        "matomo")
            local api_token=$(generate_password 32)
            replace_in_file "$env_file" "GENERATED_32_CHAR_SALT" "$api_token"
            ;;
        "glitchtip")
            local secret_key=$(generate_password 64)
            replace_in_file "$env_file" "GENERATED_64_CHAR_SECRET_KEY" "$secret_key"
            ;;
        "gitlab")
            local root_password=$(generate_password 20)
            replace_in_file "$env_file" "GENERATED_ROOT_PASSWORD" "$root_password"
            ;;
        "grafana")
            local secret_key=$(generate_password 64)
            replace_in_file "$env_file" "GENERATED_64_CHAR_SECRET" "$secret_key"
            ;;
    esac

    # Remove any backup files that might have been created
    rm -f "$env_file.bak"*

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

    for service in "${DATABASE_SERVICES[@]}"; do
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

    for service in "${BUSINESS_SERVICES[@]}"; do
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
    echo -e "${BLUE}💡 Development Tools:${NC}"
    echo "MailHog:     http://localhost:50025 (captures all emails)"
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

    # Check if templates exist - only for business services
    local templates_missing=()

    for service in "${BUSINESS_SERVICES[@]}"; do
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

    for service in "${BUSINESS_SERVICES[@]}"; do
        local service_dir="$SERVICES_DIR/$service"
        if [[ -d "$service_dir" && -f "$service_dir/.env" ]]; then
            if [[ "$found_existing" == false ]]; then
                mkdir -p "$backup_dir"
                found_existing=true
            fi

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
    echo "- All development emails captured in MailHog at http://localhost:50025"
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
    for service in "${BUSINESS_SERVICES[@]}"; do
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
