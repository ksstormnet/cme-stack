#!/bin/bash

# CME Stack Development Secrets Generator
# Generates secure credentials for all services using templates

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

DEFAULT_DB_HOST="mariadb.local"
DEFAULT_REDIS_HOST="redis.local"

echo -e "${BLUE}🔐 CME Stack Development Secrets Generator${NC}"
echo -e "${BLUE}==========================================${NC}"
echo

# Escape replacement values for safe use in sed
sed_escape() {
    # Escapes &, /, and newlines for use in sed replacement
    printf '%s' "$1" | sed -e 's/[&/\]/\\&/g' -e ':a' -e 'N' -e '$!ba' -e 's/\n/\\n/g'
}

# Function to generate secure random string
generate_password() {
    local length
    length=${1:-32}
    openssl rand -base64 "$length" | tr -d "=+/" | cut -c1-"$length"
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

    read -r -p "MariaDB Host [$DEFAULT_DB_HOST]: " DB_HOST
    DB_HOST=${DB_HOST:-$DEFAULT_DB_HOST}

    read -r -p "Redis Host [$DEFAULT_REDIS_HOST]: " REDIS_HOST
    REDIS_HOST=${REDIS_HOST:-$DEFAULT_REDIS_HOST}

    read -r -p "Redis Password (leave empty if no auth): " REDIS_PASSWORD

    read -r -p "SMTP Host (for email notifications): " SMTP_HOST
    read -r -p "SMTP User: " SMTP_USER
    read -r -s -p "SMTP Password: " SMTP_PASSWORD
    echo

    echo -e "${GREEN}✅ Configuration complete${NC}"
    echo
}

# Function to generate service credentials
generate_service_secrets() {
    local service
    service=$1
    local template_file
    template_file="$SERVICES_DIR/$service/.env.template"
    local env_file
    env_file="$SERVICES_DIR/$service/.env"

    if [[ ! -f "$template_file" ]]; then
        echo -e "${RED}❌ Template not found: $template_file${NC}"
        return 1
    fi

    echo -e "${BLUE}🔑 Generating secrets for $service...${NC}"

    mkdir -p "$SERVICES_DIR/$service"
    cp "$template_file" "$env_file"

    local db_password
    db_password=$(generate_password 32)
    local admin_password
    admin_password=$(generate_password 16)

    case $service in
        "wordpress")
            local auth_key secure_auth_key logged_in_key nonce_key auth_salt secure_auth_salt logged_in_salt nonce_salt
            auth_key=$(generate_wp_salt)
            secure_auth_key=$(generate_wp_salt)
            logged_in_key=$(generate_wp_salt)
            nonce_key=$(generate_wp_salt)
            auth_salt=$(generate_wp_salt)
            secure_auth_salt=$(generate_wp_salt)
            logged_in_salt=$(generate_wp_salt)
            nonce_salt=$(generate_wp_salt)

            sed -i.bak \
                -e "s|your-mariadb-host|$(sed_escape "$DB_HOST")|g" \
                -e "s|your-redis-host|$(sed_escape "$REDIS_HOST")|g" \
                -e "s|your-redis-password|$(sed_escape "$REDIS_PASSWORD")|g" \
                -e "s|your-smtp-host|$(sed_escape "$SMTP_HOST")|g" \
                -e "s|your-smtp-user|$(sed_escape "$SMTP_USER")|g" \
                -e "s|your-smtp-password|$(sed_escape "$SMTP_PASSWORD")|g" \
                -e "s|GENERATED_PASSWORD_32_CHARS|$(sed_escape "$db_password")|g" \
                -e "s|GENERATED_ADMIN_PASSWORD|$(sed_escape "$admin_password")|g" \
                -e "s|GENERATED_64_CHAR_SECRET|$(sed_escape "$auth_key")|g" \
                -e "s|WP_SECURE_AUTH_KEY=.*|WP_SECURE_AUTH_KEY=$(sed_escape "$secure_auth_key")|g" \
                -e "s|WP_LOGGED_IN_KEY=.*|WP_LOGGED_IN_KEY=$(sed_escape "$logged_in_key")|g" \
                -e "s|WP_NONCE_KEY=.*|WP_NONCE_KEY=$(sed_escape "$nonce_key")|g" \
                -e "s|WP_AUTH_SALT=.*|WP_AUTH_SALT=$(sed_escape "$auth_salt")|g" \
                -e "s|WP_SECURE_AUTH_SALT=.*|WP_SECURE_AUTH_SALT=$(sed_escape "$secure_auth_salt")|g" \
                -e "s|WP_LOGGED_IN_SALT=.*|WP_LOGGED_IN_SALT=$(sed_escape "$logged_in_salt")|g" \
                -e "s|WP_NONCE_SALT=.*|WP_NONCE_SALT=$(sed_escape "$nonce_salt")|g" \
                "$env_file"
            ;;
        "n8n")
            local encryption_key
            encryption_key=$(generate_password 64)
            sed -i.bak \
                -e "s|your-mariadb-host|$(sed_escape "$DB_HOST")|g" \
                -e "s|your-smtp-host|$(sed_escape "$SMTP_HOST")|g" \
                -e "s|your-smtp-user|$(sed_escape "$SMTP_USER")|g" \
                -e "s|your-smtp-password|$(sed_escape "$SMTP_PASSWORD")|g" \
                -e "s|GENERATED_PASSWORD_32_CHARS|$(sed_escape "$db_password")|g" \
                -e "s|GENERATED_ADMIN_PASSWORD|$(sed_escape "$admin_password")|g" \
                -e "s|GENERATED_64_CHAR_ENCRYPTION_KEY|$(sed_escape "$encryption_key")|g" \
                "$env_file"
            ;;
        "gitlab")
            local root_password
            root_password=$(generate_password 20)
            sed -i.bak \
                -e "s|your-mariadb-host|$(sed_escape "$DB_HOST")|g" \
                -e "s|your-redis-host|$(sed_escape "$REDIS_HOST")|g" \
                -e "s|your-redis-password|$(sed_escape "$REDIS_PASSWORD")|g" \
                -e "s|your-smtp-host|$(sed_escape "$SMTP_HOST")|g" \
                -e "s|your-smtp-user|$(sed_escape "$SMTP_USER")|g" \
                -e "s|your-smtp-password|$(sed_escape "$SMTP_PASSWORD")|g" \
                -e "s|GENERATED_PASSWORD_32_CHARS|$(sed_escape "$db_password")|g" \
                -e "s|GENERATED_ROOT_PASSWORD|$(sed_escape "$root_password")|g" \
                "$env_file"
            ;;
        *)
            sed -i.bak \
                -e "s|your-mariadb-host|$(sed_escape "$DB_HOST")|g" \
                -e "s|your-redis-host|$(sed_escape "$REDIS_HOST")|g" \
                -e "s|your-redis-password|$(sed_escape "$REDIS_PASSWORD")|g" \
                -e "s|your-smtp-host|$(sed_escape "$SMTP_HOST")|g" \
                -e "s|your-smtp-user|$(sed_escape "$SMTP_USER")|g" \
                -e "s|your-smtp-password|$(sed_escape "$SMTP_PASSWORD")|g" \
                -e "s|GENERATED_PASSWORD_32_CHARS|$(sed_escape "$db_password")|g" \
                -e "s|GENERATED_PASSWORD_16_CHARS|$(sed_escape "$(generate_password 16)")|g" \
                -e "s|GENERATED_ADMIN_PASSWORD|$(sed_escape "$admin_password")|g" \
                -e "s|GENERATED_64_CHAR_SECRET|$(sed_escape "$(generate_password 64)")|g" \
                -e "s|GENERATED_64_CHAR_SECRET_KEY|$(sed_escape "$(generate_password 64)")|g" \
                -e "s|GENERATED_32_CHAR_SALT|$(sed_escape "$(generate_password 32)")|g" \
                "$env_file"
            ;;
    esac

    rm -f "$env_file.bak"

    SERVICE_CREDENTIALS["$service"]="$db_password"
    ADMIN_PASSWORDS["$service"]="$admin_password"

    echo -e "${GREEN}✅ Generated $service secrets${NC}"
}

generate_sql_commands() {
    echo -e "${YELLOW}📊 Database Setup Commands${NC}"
    echo -e "${YELLOW}=========================${NC}"
    echo
    echo "-- Run these commands on your MariaDB server:"
    echo

    for service in wordpress matomo n8n glitchtip gitlab grafana; do
        if [[ -n "${SERVICE_CREDENTIALS[$service]:-}" ]]; then
            local password
            password="${SERVICE_CREDENTIALS[$service]}"
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

display_admin_credentials() {
    echo -e "${YELLOW}🔑 Admin Credentials${NC}"
    echo -e "${YELLOW}==================${NC}"
    echo
    echo "Save these admin credentials securely:"
    echo

    for service in wordpress matomo n8n glitchtip gitlab grafana; do
        if [[ -n "${ADMIN_PASSWORDS[$service]:-}" ]]; then
            local password
            password="${ADMIN_PASSWORDS[$service]}"
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

check_prerequisites() {
    echo -e "${BLUE}🔍 Checking prerequisites...${NC}"

    local missing=()

    if ! command -v openssl &> /dev/null; then
        missing+=("openssl")
    fi

    if [[ ${#missing[@]} -gt 0 ]]; then
        echo -e "${RED}❌ Missing required tools: ${missing[*]}${NC}"
        echo "Please install the missing tools and try again."
        exit 1
    fi

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

backup_existing_env() {
    echo -e "${BLUE}💾 Backing up existing .env files...${NC}"

    local backup_dir
    backup_dir="$PROJECT_ROOT/temp-secrets/backup-$(date +%Y%m%d-%H%M%S)"
    local found_existing=false

    for service_dir in "$SERVICES_DIR"/*; do
        if [[ -d "$service_dir" && -f "$service_dir/.env" ]]; then
            if [[ "$found_existing" == false ]]; then
                mkdir -p "$backup_dir"
                found_existing=true
            fi

            local service
            service=$(basename "$service_dir")
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

main() {
    if [[ ! -f "$PROJECT_ROOT/docker-compose.base.yml" ]]; then
        echo -e "${RED}❌ Please run this script from the CME project root directory${NC}"
        exit 1
    fi

    declare -gA SERVICE_CREDENTIALS
    declare -gA ADMIN_PASSWORDS

    check_prerequisites
    backup_existing_env
    prompt_config

    echo -e "${BLUE}🔐 Generating secrets for all services...${NC}"
    echo

    local services
    services=("wordpress" "matomo" "n8n" "glitchtip" "gitlab" "grafana" "prometheus")

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

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
