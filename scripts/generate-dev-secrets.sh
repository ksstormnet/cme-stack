#!/bin/bash

# CME Stack Development Secrets Generator
# Generates secure credentials for all services using templates
# 
# Usage: ./scripts/generate-dev-secrets.sh
#
# This script:
# 1. Generates secure random passwords and keys
# 2. Creates .env files from templates with real values
# 3. Outputs SQL commands for database setup
# 4. Maintains security by never committing actual secrets

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

# Default database and Redis hosts (customize these)
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
    
    # Replace placeholders in .env file
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
            
            sed -i.bak \
                -e "s/your-mariadb-host/$DB_HOST/g" \
                -e "s/your-redis-host/$REDIS_HOST/g" \
                -e "s/your-redis-password/$REDIS_PASSWORD/g" \
                -e "s/your-smtp-host/$SMTP_HOST/g" \
                -e "s/your-smtp-user/$SMTP_USER/g" \
                -e "s/your-smtp-password/$SMTP_PASSWORD/g" \
                -e "s/GENERATED_PASSWORD_32_CHARS/$db_password/g" \
                -e "s/GENERATED_ADMIN_PASSWORD/$admin_password/g" \
                -e "s/GENERATED_64_CHAR_SECRET/$auth_key/g" \
                -e "s/WP_SECURE_AUTH_KEY=.*/WP_SECURE_AUTH_KEY=$secure_auth_key/g" \
                -e "s/WP_LOGGED_IN_KEY=.*/WP_LOGGED_IN_KEY=$logged_in_key/g" \
                -e "s/WP_NONCE_KEY=.*/WP_NONCE_KEY=$nonce_key/g" \
                -e "s/WP_AUTH_SALT=.*/WP_AUTH_SALT=$auth_salt/g" \
                -e "s/WP_SECURE_AUTH_SALT=.*/WP_SECURE_AUTH_SALT=$secure_auth_salt/g" \
                -e "s/WP_LOGGED_IN_SALT=.*/WP_LOGGED_IN_SALT=$logged_in_salt/g" \
                -e "s/WP_NONCE_SALT=.*/WP_NONCE_SALT=$nonce_salt/g" \
                "$env_file"
            ;;
        "n8n")
            local encryption_key=$(generate_password 64)
            sed -i.bak \
                -e "s/your-mariadb-host/$DB_HOST/g" \
                -e "s/your-smtp-host/$SMTP_HOST/g" \
                -e "s/your-smtp-user/$SMTP_USER/g" \
                -e "s/your-smtp-password/$SMTP_PASSWORD/g" \
                -e "s/GENERATED_PASSWORD_32_CHARS/$db_password/g" \
                -e "s/GENERATED_ADMIN_PASSWORD/$admin_password/g" \
                -e "s/GENERATED_64_CHAR_ENCRYPTION_KEY/$encryption_key/g" \
                "$env_file"
            ;;
        "gitlab")
            local root_password=$(generate_password 20)
            sed -i.bak \
                -e "s/your-mariadb-host/$DB_HOST/g" \
                -e "s/your-redis-host/$REDIS_HOST/g" \
                -e "s/your-redis-password/$REDIS_PASSWORD/g" \
                -e "s/your-smtp-host/$SMTP_HOST/g" \
                -e "s/your-smtp-user/$SMTP_USER/g" \
                -e "s/your-smtp-password/$SMTP_PASSWORD/g" \
                -e "s/GENERATED_PASSWORD_32_CHARS/$db_password/g" \
                -e "s/GENERATED_ROOT_PASSWORD/$root_password/g" \
                "$env_file"
            ;;
        *)
            # Generic replacements for other services
            sed -i.bak \
                -e "s/your-mariadb-host/$DB_HOST/g" \
                -e "s/your-redis-host/$REDIS_HOST/g" \
                -e "s/your-redis-password/$REDIS_PASSWORD/g" \
                -e "s/your-smtp-host/$SMTP_HOST/g" \
                -e "s/your-smtp-user/$SMTP_USER/g" \
                -e "s/your-smtp-password/$SMTP_PASSWORD/g" \
                -e "s/GENERATED_PASSWORD_32_CHARS/$db_password/g" \
                -e "s/GENERATED_PASSWORD_16_CHARS/$(generate_password 16)/g" \
                -e "s/GENERATED_ADMIN_PASSWORD/$admin_password/g" \
                -e "s/GENERATED_64_CHAR_SECRET/$(generate_password 64)/g" \
                -e "s/GENERATED_64_CHAR_SECRET_KEY/$(generate_password 64)/g" \
                -e "s/GENERATED_32_CHAR_SALT/$(generate_password 32)/g" \
                "$env_file"
            ;;
    esac
    
    # Remove backup file
    rm -f "$env_file.bak"
    
    # Store credentials for SQL generation
    SERVICE_CREDENTIALS[$service]="$db_password"
    ADMIN_PASSWORDS[$service]="$admin_password"
    
    echo -e "${GREEN}✅ Generated $service secrets${NC}"
}

# Function to generate SQL commands
generate_sql_commands() {
    echo -e "${YELLOW}📊 Database Setup Commands${NC}"
    echo -e "${YELLOW}=========================${NC}"
    echo
    echo "-- Run these commands on your MariaDB server:"
    echo
    
    for service in wordpress matomo n8n glitchtip gitlab grafana; do
        if [[ -n "${SERVICE_CREDENTIALS[$service]:-}" ]]; then
            local password="${SERVICE_CREDENTIALS[$service]}"
            echo "-- $service database and user"
            echo "CREATE DATABASE IF NOT EXISTS cme_dev_$service;"
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
            echo -e "$service: ${GREEN}admin${NC} / ${GREEN}$password${NC}"
        fi
    done
    
    echo
    echo -e "${BLUE}💡 Service URLs (development):${NC}"
    echo "WordPress:  https://dev-wordpress.cme.ksstorm.dev"
    echo "Matomo:     https://dev-matomo.cme.ksstorm.dev"
    echo "n8n:        https://dev-n8n.cme.ksstorm.dev"
    echo "GlitchTip:  https://dev-glitchtip.cme.ksstorm.dev"
    echo "GitLab:     https://dev-gitlab.cme.ksstorm.dev"
    echo "Grafana:    https://dev-grafana.cme.ksstorm.dev"
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
    
    # Check if templates exist
    local templates_missing=()
    local services=("wordpress" "matomo" "n8n" "glitchtip" "gitlab" "grafana" "prometheus")
    
    for service in "${services[@]}"; do
        if [[ ! -f "$SERVICES_DIR/$service/.env.template" ]]; then
            templates_missing+=("$service")
        fi
    done
    
    if [[ ${#templates_missing[@]} -gt 0 ]]; then
        echo -e "${RED}❌ Missing .env.template files for: ${templates_missing[*]}${NC}"
        echo "Please ensure all template files are present."
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
    echo "   ${GREEN}./scripts/compose-dev.sh dev${NC}"
    echo
    echo "3. Access services using the URLs and credentials listed above"
    echo
    echo "4. For additional services (infrastructure/monitoring):"
    echo "   ${GREEN}./scripts/compose-dev.sh start infrastructure${NC}"
    echo "   ${GREEN}./scripts/compose-dev.sh start monitoring${NC}"
    echo
    echo -e "${BLUE}💡 Tips:${NC}"
    echo "- All .env files are ignored by git (never committed)"
    echo "- Re-run this script anytime to regenerate credentials"
    echo "- Backup files are kept in temp-secrets/ for recovery"
    echo
    echo -e "${GREEN}✅ Development secrets setup complete!${NC}"
}

# Main execution
main() {
    # Check if running from correct directory
    if [[ ! -f "$PROJECT_ROOT/docker-compose.core.yml" ]]; then
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
    
    echo -e "${BLUE}🔐 Generating secrets for all services...${NC}"
    echo
    
    # Generate secrets for each service
    local services=("wordpress" "matomo" "n8n" "glitchtip" "gitlab" "grafana" "prometheus")
    
    for service in "${services[@]}"; do
        generate_service_secrets "$service"
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