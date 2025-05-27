#!/bin/bash

# ================================================================
# Simple Development Secrets Generator
# ================================================================
# Generates secure secrets directly into .env.dev file
# No 1Password Connect required - for development only
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
ENV_TEMPLATE="${PROJECT_DIR}/.env.dev.template"

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
# SECRET GENERATION FUNCTIONS
# ================================================================

# Generate different types of secrets
generate_password() {
    local length=${1:-32}
    openssl rand -base64 "$length" | tr -d "=+/" | cut -c1-25
}

generate_long_password() {
    openssl rand -base64 48 | tr -d "=+/" | cut -c1-32
}

generate_hex_key() {
    local length=${1:-32}
    openssl rand -hex "$length"
}

generate_django_secret() {
    python3 -c "
import secrets
import string
chars = string.ascii_letters + string.digits + '!@#$%^&*(-_=+)'
print(''.join(secrets.choice(chars) for _ in range(50)))
" 2>/dev/null || openssl rand -base64 64 | tr -d "=+/" | cut -c1-50
}

generate_uuid() {
    python3 -c "import uuid; print(str(uuid.uuid4()))" 2>/dev/null || uuidgen 2>/dev/null || echo "$(openssl rand -hex 16 | sed 's/\(..\)\(..\)\(..\)\(..\)\(..\)\(..\)\(..\)\(..\)\(..\)\(..\)\(..\)\(..\)\(..\)\(..\)\(..\)\(..\)/\1\2\3\4-\5\6-\7\8-\9\10-\11\12\13\14\15\16/')"
}

# ================================================================
# ENVIRONMENT FILE MANAGEMENT
# ================================================================

create_env_file() {
    log "Creating .env.dev file from template..."

    if [[ ! -f "$ENV_TEMPLATE" ]]; then
        error "Template file $ENV_TEMPLATE not found"
    fi

    # Copy template to .env.dev
    cp "$ENV_TEMPLATE" "$ENV_FILE"

    info "Environment file created from template"
}

update_env_var() {
    local var_name="$1"
    local var_value="$2"

    # Escape special characters for sed
    local escaped_value=$(printf '%s\n' "$var_value" | sed 's/[[\.*^$()+?{|]/\\&/g')

    if grep -q "^${var_name}=" "$ENV_FILE"; then
        # Update existing variable
        if [[ "$OSTYPE" == "darwin"* ]]; then
            sed -i '' "s|^${var_name}=.*|${var_name}=${escaped_value}|" "$ENV_FILE"
        else
            sed -i "s|^${var_name}=.*|${var_name}=${escaped_value}|" "$ENV_FILE"
        fi
    else
        # Add new variable
        echo "${var_name}=${var_value}" >> "$ENV_FILE"
    fi

    info "Updated ${var_name}"
}

# ================================================================
# SECRET GENERATION AND INJECTION
# ================================================================

generate_all_secrets() {
    log "Generating all development secrets..."

    # Database passwords
    info "Generating database credentials..."
    update_env_var "MYSQL_ROOT_PASSWORD" "$(generate_long_password)"
    update_env_var "WORDPRESS_DB_PASSWORD" "$(generate_password)"
    update_env_var "MATOMO_DB_PASSWORD" "$(generate_password)"
    update_env_var "N8N_DB_PASSWORD" "$(generate_password)"
    update_env_var "GLITCHTIP_DB_PASSWORD" "$(generate_password)"

    # Application passwords
    info "Generating application credentials..."
    update_env_var "WP_ADMIN_PASSWORD" "$(generate_long_password)"
    update_env_var "N8N_BASIC_AUTH_PASSWORD" "$(generate_password)"
    update_env_var "GITLAB_ROOT_PASSWORD" "$(generate_long_password)"
    update_env_var "GRAFANA_ADMIN_PASSWORD" "$(generate_password)"

    # Application secrets
    info "Generating application secrets..."
    update_env_var "GLITCHTIP_SECRET_KEY" "$(generate_django_secret)"
    update_env_var "JWT_SECRET" "$(generate_hex_key 64)"
    update_env_var "CACHE_PURGE_KEY" "$(generate_password)"
    update_env_var "SESSION_SECRET" "$(generate_hex_key 32)"

    # API Keys placeholders
    info "Setting up API key placeholders..."
    update_env_var "OPENAI_API_KEY" "sk-placeholder-openai-key-replace-with-real"
    update_env_var "GHL_API_KEY" "placeholder-ghl-key-replace-with-real"
    update_env_var "GHL_LOCATION_ID" "placeholder-ghl-location-id"
    update_env_var "MATOMO_TOKEN" "placeholder-matomo-token-generate-in-settings"
    update_env_var "VOIPMS_API_KEY" "placeholder-voipms-key"
    update_env_var "VOIPMS_API_PASSWORD" "placeholder-voipms-password"

    log "All secrets generated successfully!"
}

# ================================================================
# DATABASE SETUP HELPER
# ================================================================

show_database_commands() {
    log "Database setup commands for your MariaDB server:"
    echo ""
    echo -e "${BLUE}Run these commands on your MariaDB host:${NC}"
    echo ""

    # Extract passwords from env file
    local wp_pass=$(grep "^WORDPRESS_DB_PASSWORD=" "$ENV_FILE" | cut -d'=' -f2)
    local matomo_pass=$(grep "^MATOMO_DB_PASSWORD=" "$ENV_FILE" | cut -d'=' -f2)
    local n8n_pass=$(grep "^N8N_DB_PASSWORD=" "$ENV_FILE" | cut -d'=' -f2)
    local glitch_pass=$(grep "^GLITCHTIP_DB_PASSWORD=" "$ENV_FILE" | cut -d'=' -f2)

    cat << EOF
# Create databases
CREATE DATABASE cme_wordpress CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE DATABASE cme_matomo CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE DATABASE cme_n8n CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE DATABASE cme_glitchtip CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

# Create users with generated passwords
CREATE USER 'wordpress_user'@'%' IDENTIFIED BY '${wp_pass}';
CREATE USER 'matomo_user'@'%' IDENTIFIED BY '${matomo_pass}';
CREATE USER 'n8n_user'@'%' IDENTIFIED BY '${n8n_pass}';
CREATE USER 'glitchtip_user'@'%' IDENTIFIED BY '${glitch_pass}';

# Grant privileges
GRANT ALL PRIVILEGES ON cme_wordpress.* TO 'wordpress_user'@'%';
GRANT ALL PRIVILEGES ON cme_matomo.* TO 'matomo_user'@'%';
GRANT ALL PRIVILEGES ON cme_n8n.* TO 'n8n_user'@'%';
GRANT ALL PRIVILEGES ON cme_glitchtip.* TO 'glitchtip_user'@'%';

FLUSH PRIVILEGES;
EOF
    echo ""
    info "Copy and paste these commands into your MariaDB console"
}

# ================================================================
# UTILITY FUNCTIONS
# ================================================================

show_status() {
    log "Development Environment Status"
    echo ""

    if [[ -f "$ENV_FILE" ]]; then
        echo -e "${BLUE}Environment file: ${GREEN}✓ Created${NC}"

        # Count generated secrets
        local secret_count=$(grep -c "^[A-Z_]*PASSWORD=" "$ENV_FILE" || echo "0")
        echo -e "${BLUE}Generated secrets: ${GREEN}${secret_count} passwords${NC}"

        # Show API key placeholders
        echo -e "${BLUE}API keys to configure:${NC}"
        echo "  - OpenAI API Key (get from: https://platform.openai.com/api-keys)"
        echo "  - GoHighLevel API Key (get from GHL developer settings)"
        echo "  - Matomo Token (generate in Matomo settings)"
        echo "  - VoIP.ms API credentials (get from account portal)"
        echo ""

    else
        echo -e "${BLUE}Environment file: ${RED}✗ Not found${NC}"
    fi

    echo -e "${BLUE}Next steps:${NC}"
    echo "1. Run database setup commands (shown above)"
    echo "2. Update API key placeholders in .env.dev with real values"
    echo "3. Start services: docker compose --env-file .env.dev -f docker-compose.dev.yml up -d"
    echo ""
}

backup_existing_env() {
    if [[ -f "$ENV_FILE" ]]; then
        local backup_file="${ENV_FILE}.backup.$(date +%Y%m%d_%H%M%S)"
        cp "$ENV_FILE" "$backup_file"
        warn "Existing .env.dev backed up to $(basename "$backup_file")"
    fi
}

# ================================================================
# MAIN EXECUTION
# ================================================================

show_usage() {
    echo "Usage: $0 [command]"
    echo ""
    echo "Commands:"
    echo "  generate    - Generate all secrets (default)"
    echo "  status      - Show current status"
    echo "  db-setup    - Show database setup commands"
    echo "  backup      - Backup existing .env.dev file"
    echo ""
    echo "Examples:"
    echo "  $0                  # Generate all secrets"
    echo "  $0 generate         # Same as above"
    echo "  $0 status           # Show environment status"
    echo "  $0 db-setup         # Show database commands"
}

main() {
    echo -e "${GREEN}"
    echo "================================================================"
    echo "  CME Development Secrets Generator"
    echo "================================================================"
    echo -e "${NC}"

    case "${1:-generate}" in
        "generate")
            backup_existing_env
            create_env_file
            generate_all_secrets
            show_database_commands
            show_status
            ;;
        "status")
            show_status
            ;;
        "db-setup")
            if [[ ! -f "$ENV_FILE" ]]; then
                error "Environment file not found. Run '$0 generate' first."
            fi
            show_database_commands
            ;;
        "backup")
            backup_existing_env
            ;;
        *)
            show_usage
            exit 1
            ;;
    esac
}

# Run main function with all arguments
main "$@"
