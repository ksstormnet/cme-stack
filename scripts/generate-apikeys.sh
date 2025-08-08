#!/bin/bash

# File: scripts/generate-apikeys.sh
# CME Stack API Keys Updater
# Updates API keys in existing .env files without touching database credentials
#
# Usage: ./scripts/generate-apikeys.sh

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

# Services that use API keys
API_SERVICES=("wordpress" "n8n")

echo -e "${BLUE}🔑 CME Stack API Keys Updater${NC}"
echo -e "${BLUE}==============================${NC}"
echo

# Function to replace placeholders in file using perl
replace_in_file() {
    local file="$1"
    local find="$2"
    local replace="$3"

    # Use perl for reliable substitution
    perl -i -pe "s/\Q$find\E/$replace/g" "$file"
}

# Function to prompt for API keys
prompt_for_api_keys() {
    echo -e "${YELLOW}🔗 API Key Configuration${NC}"
    echo "Enter your external API keys (press Enter to skip):"
    echo

    read -p "OpenAI API Key: " OPENAI_API_KEY
    read -p "GoHighLevel API Key: " GHL_API_KEY
    read -p "GoHighLevel Location ID: " GHL_LOCATION_ID

    echo
    echo -e "${BLUE}VoIP.ms uses different authentication:${NC}"
    read -p "VoIP.ms Bearer Token: " VOIPMS_BEARER_TOKEN
    read -p "VoIP.ms API Password: " VOIPMS_API_PASSWORD

    echo -e "${GREEN}✅ API key input complete${NC}"
    echo
}

# Function to update API keys in service .env file
update_service_api_keys() {
    local service=$1
    local env_file="$SERVICES_DIR/$service/.env"

    if [[ ! -f "$env_file" ]]; then
        echo -e "${YELLOW}⚠️  No .env file found for $service, skipping...${NC}"
        return 0
    fi

    echo -e "${BLUE}🔄 Updating API keys for $service...${NC}"

    # Create backup
    cp "$env_file" "$env_file.backup-$(date +%Y%m%d-%H%M%S)"

    # Update API keys - only replace if they exist in template
    if grep -q "OPENAI_API_KEY=" "$env_file"; then
        replace_in_file "$env_file" "your-openai-api-key" "$OPENAI_API_KEY"
        # Also handle if it was previously set to empty or placeholder
        perl -i -pe "s/^OPENAI_API_KEY=.*/OPENAI_API_KEY=$OPENAI_API_KEY/" "$env_file"
    fi

    if grep -q "GHL_API_KEY=" "$env_file"; then
        replace_in_file "$env_file" "your-ghl-api-key" "$GHL_API_KEY"
        perl -i -pe "s/^GHL_API_KEY=.*/GHL_API_KEY=$GHL_API_KEY/" "$env_file"
    fi

    if grep -q "GHL_LOCATION_ID=" "$env_file"; then
        replace_in_file "$env_file" "your-ghl-location-id" "$GHL_LOCATION_ID"
        perl -i -pe "s/^GHL_LOCATION_ID=.*/GHL_LOCATION_ID=$GHL_LOCATION_ID/" "$env_file"
    fi

    if grep -q "VOIPMS_BEARER_TOKEN=" "$env_file"; then
        replace_in_file "$env_file" "your-voipms-bearer-token" "$VOIPMS_BEARER_TOKEN"
        perl -i -pe "s/^VOIPMS_BEARER_TOKEN=.*/VOIPMS_BEARER_TOKEN=$VOIPMS_BEARER_TOKEN/" "$env_file"
    fi

    if grep -q "VOIPMS_API_PASSWORD=" "$env_file"; then
        replace_in_file "$env_file" "your-voipms-api-password" "$VOIPMS_API_PASSWORD"
        perl -i -pe "s/^VOIPMS_API_PASSWORD=.*/VOIPMS_API_PASSWORD=$VOIPMS_API_PASSWORD/" "$env_file"
    fi

    # Legacy support for old VOIPMS_API_KEY field (if it exists)
    if grep -q "VOIPMS_API_KEY=" "$env_file"; then
        replace_in_file "$env_file" "your-voipms-api-key" "$VOIPMS_BEARER_TOKEN"
        perl -i -pe "s/^VOIPMS_API_KEY=.*/VOIPMS_API_KEY=$VOIPMS_BEARER_TOKEN/" "$env_file"
    fi

    echo -e "${GREEN}✅ Updated $service API keys${NC}"
}

# Function to check prerequisites
check_prerequisites() {
    echo -e "${BLUE}🔍 Checking for existing .env files...${NC}"

    local missing_services=()
    local found_services=()

    for service in "${API_SERVICES[@]}"; do
        if [[ -f "$SERVICES_DIR/$service/.env" ]]; then
            found_services+=("$service")
        else
            missing_services+=("$service")
        fi
    done

    if [[ ${#found_services[@]} -eq 0 ]]; then
        echo -e "${RED}❌ No .env files found for API key services${NC}"
        echo -e "${YELLOW}💡 Run ./scripts/generate-dev-secrets.sh first to create base .env files${NC}"
        exit 1
    fi

    echo -e "${GREEN}✅ Found .env files for: ${found_services[*]}${NC}"

    if [[ ${#missing_services[@]} -gt 0 ]]; then
        echo -e "${YELLOW}⚠️  Missing .env files for: ${missing_services[*]}${NC}"
        echo -e "${YELLOW}   These services will be skipped${NC}"
    fi

    echo
}

# Function to show what will be updated
show_update_preview() {
    echo -e "${YELLOW}🔍 API Keys Update Preview${NC}"
    echo -e "${YELLOW}=========================${NC}"
    echo

    for service in "${API_SERVICES[@]}"; do
        local env_file="$SERVICES_DIR/$service/.env"
        if [[ -f "$env_file" ]]; then
            echo -e "${BLUE}$service:${NC}"

            # Show which API keys will be updated
            if grep -q "OPENAI_API_KEY=" "$env_file"; then
                local current_openai=$(grep "^OPENAI_API_KEY=" "$env_file" | cut -d'=' -f2)
                if [[ -n "$OPENAI_API_KEY" ]]; then
                    echo "  OpenAI API Key: ${current_openai:0:10}... → ${OPENAI_API_KEY:0:10}..."
                else
                    echo "  OpenAI API Key: ${current_openai:0:10}... → (skip - no new key provided)"
                fi
            fi

            if grep -q "GHL_API_KEY=" "$env_file"; then
                local current_ghl=$(grep "^GHL_API_KEY=" "$env_file" | cut -d'=' -f2)
                if [[ -n "$GHL_API_KEY" ]]; then
                    echo "  GoHighLevel API Key: ${current_ghl:0:10}... → ${GHL_API_KEY:0:10}..."
                else
                    echo "  GoHighLevel API Key: ${current_ghl:0:10}... → (skip - no new key provided)"
                fi
            fi

            if grep -q "GHL_LOCATION_ID=" "$env_file"; then
                local current_location=$(grep "^GHL_LOCATION_ID=" "$env_file" | cut -d'=' -f2)
                if [[ -n "$GHL_LOCATION_ID" ]]; then
                    echo "  GoHighLevel Location ID: $current_location → $GHL_LOCATION_ID"
                else
                    echo "  GoHighLevel Location ID: $current_location → (skip - no new ID provided)"
                fi
            fi

            if grep -q "VOIPMS_BEARER_TOKEN=" "$env_file"; then
                local current_bearer=$(grep "^VOIPMS_BEARER_TOKEN=" "$env_file" | cut -d'=' -f2)
                if [[ -n "$VOIPMS_BEARER_TOKEN" ]]; then
                    echo "  VoIP.ms Bearer Token: ${current_bearer:0:10}... → ${VOIPMS_BEARER_TOKEN:0:10}..."
                else
                    echo "  VoIP.ms Bearer Token: ${current_bearer:0:10}... → (skip - no new token provided)"
                fi
            fi

            if grep -q "VOIPMS_API_PASSWORD=" "$env_file"; then
                local current_password=$(grep "^VOIPMS_API_PASSWORD=" "$env_file" | cut -d'=' -f2)
                if [[ -n "$VOIPMS_API_PASSWORD" ]]; then
                    echo "  VoIP.ms API Password: ${current_password:0:6}... → ${VOIPMS_API_PASSWORD:0:6}..."
                else
                    echo "  VoIP.ms API Password: ${current_password:0:6}... → (skip - no new password provided)"
                fi
            fi

            # Legacy field support
            if grep -q "VOIPMS_API_KEY=" "$env_file" && [[ ! -f "$env_file" =~ VOIPMS_BEARER_TOKEN ]]; then
                local current_voip=$(grep "^VOIPMS_API_KEY=" "$env_file" | cut -d'=' -f2)
                if [[ -n "$VOIPMS_BEARER_TOKEN" ]]; then
                    echo "  VoIP.ms API Key (legacy): ${current_voip:0:10}... → ${VOIPMS_BEARER_TOKEN:0:10}..."
                else
                    echo "  VoIP.ms API Key (legacy): ${current_voip:0:10}... → (skip - no new key provided)"
                fi
            fi

            echo
        fi
    done
}

# Function to show completion summary
show_completion_summary() {
    echo -e "${GREEN}🎉 API Keys Update Complete!${NC}"
    echo -e "${GREEN}============================${NC}"
    echo
    echo "Services updated:"

    for service in "${API_SERVICES[@]}"; do
        if [[ -f "$SERVICES_DIR/$service/.env" ]]; then
            echo -e "  ✅ $service"
        fi
    done

    echo
    echo -e "${BLUE}💡 Next Steps:${NC}"
    echo "- API keys are now configured in your .env files"
    echo "- Services will use these keys when started/restarted"
    echo "- Backup files created with timestamp for rollback if needed"
    echo
    echo "To apply the new API keys:"
    echo "  ${GREEN}docker-compose -f docker-compose.dev.yml restart${NC}"
    echo
}

# Main execution
main() {
    # Check if running from correct directory
    if [[ ! -f "$PROJECT_ROOT/docker-compose.dev.yml" ]]; then
        echo -e "${RED}❌ Please run this script from the CME project root directory${NC}"
        exit 1
    fi

    # Check for existing .env files
    check_prerequisites

    # Get API keys from user
    prompt_for_api_keys

    # Show what will be updated
    show_update_preview

    # Confirm before proceeding
    echo -e "${YELLOW}❓ Proceed with API key updates? [y/N]${NC}"
    read -r confirm
    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
        echo -e "${BLUE}ℹ️  API key update cancelled${NC}"
        exit 0
    fi

    echo
    echo -e "${BLUE}🔄 Updating API keys...${NC}"
    echo

    # Update API keys for each service
    for service in "${API_SERVICES[@]}"; do
        update_service_api_keys "$service"
    done

    echo
    show_completion_summary
}

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
