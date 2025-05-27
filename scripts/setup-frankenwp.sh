#!/bin/bash

# ================================================================
# FrankenWP Directory Setup Script
# ================================================================
# Creates the proper directory structure and files for FrankenWP
# ================================================================

set -euo pipefail

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] $1${NC}"
}

info() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')] INFO: $1${NC}"
}

create_frankenwp_structure() {
    log "Creating FrankenWP directory structure..."

    # Create WordPress directories
    mkdir -p "${PROJECT_DIR}/services/wordpress/wp-content/"{themes,plugins,uploads,cache}
    mkdir -p "${PROJECT_DIR}/services/wordpress/"{db-backup,root-files,caddy-config,setup-scripts}

    # Create basic wp-config.php
    cat > "${PROJECT_DIR}/services/wordpress/root-files/wp-config.php" << 'EOF'
<?php
/**
 * Custom wp-config.php for CME FrankenWP Development
 * This file overrides the default WordPress configuration
 */

// ** MySQL settings - You can get this info from your web host ** //
/** The name of the database for WordPress */
define( 'DB_NAME', getenv('WORDPRESS_DB_NAME') ?: 'cme_wordpress' );

/** MySQL database username */
define( 'DB_USER', getenv('WORDPRESS_DB_USER') ?: 'wordpress_user' );

/** MySQL database password */
define( 'DB_PASSWORD', getenv('WORDPRESS_DB_PASSWORD') ?: '' );

/** MySQL hostname */
define( 'DB_HOST', getenv('WORDPRESS_DB_HOST') ?: 'mariadb' );

/** Database Charset to use in creating database tables. */
define( 'DB_CHARSET', 'utf8mb4' );

/** The Database Collate type. Don't change this if in doubt. */
define( 'DB_COLLATE', '' );

/** Table prefix */
$table_prefix = getenv('WORDPRESS_TABLE_PREFIX') ?: 'wp_dev_';

/**#@+
 * Authentication Unique Keys and Salts.
 * Generate these at: https://api.wordpress.org/secret-key/1.1/salt/
 */
define('AUTH_KEY',         'dev-auth-key-change-in-production');
define('SECURE_AUTH_KEY',  'dev-secure-auth-key-change-in-production');
define('LOGGED_IN_KEY',    'dev-logged-in-key-change-in-production');
define('NONCE_KEY',        'dev-nonce-key-change-in-production');
define('AUTH_SALT',        'dev-auth-salt-change-in-production');
define('SECURE_AUTH_SALT', 'dev-secure-auth-salt-change-in-production');
define('LOGGED_IN_SALT',   'dev-logged-in-salt-change-in-production');
define('NONCE_SALT',       'dev-nonce-salt-change-in-production');

/**#@-*/

/**
 * WordPress Database Table prefix.
 */
$table_prefix = getenv('WORDPRESS_TABLE_PREFIX') ?: 'wp_dev_';

/**
 * For developers: WordPress debugging mode.
 */
define( 'WP_DEBUG', true );
define( 'WP_DEBUG_LOG', true );
define( 'WP_DEBUG_DISPLAY', false );
define( 'SCRIPT_DEBUG', true );

/**
 * CME-specific configuration
 */
define( 'CME_ENVIRONMENT', 'development' );
define( 'CME_VERSION', '1.0.0-dev' );

// Site URLs (will be overridden by WORDPRESS_CONFIG_EXTRA)
define( 'WP_HOME', 'https://dev-wordpress.cme.ksstorm.dev' );
define( 'WP_SITEURL', 'https://dev-wordpress.cme.ksstorm.dev' );

// Cache settings for FrankenWP
define( 'WP_CACHE', true );
define( 'WPCACHEHOME', '/var/www/html/wp-content/cache/' );

// Disable file editing in admin
define( 'DISALLOW_FILE_EDIT', true );

// Memory and execution limits
define( 'WP_MEMORY_LIMIT', '512M' );
ini_set( 'max_execution_time', 300 );

// Security settings for development
define( 'FORCE_SSL_ADMIN', false );
define( 'AUTOMATIC_UPDATER_DISABLED', true );

/* That's all, stop editing! Happy publishing. */

/** Absolute path to the WordPress directory. */
if ( ! defined( 'ABSPATH' ) ) {
    define( 'ABSPATH', __DIR__ . '/' );
}

/** Sets up WordPress vars and included files. */
require_once ABSPATH . 'wp-settings.php';
EOF

    # Create basic Caddyfile for custom routing if needed
    cat > "${PROJECT_DIR}/services/wordpress/caddy-config/Caddyfile" << 'EOF'
# Custom Caddy configuration for CME WordPress
# This file is optional - FrankenWP has built-in Caddy config

:80 {
    # Custom headers for development
    header {
        # Security headers
        X-Frame-Options "SAMEORIGIN"
        X-Content-Type-Options "nosniff"
        Referrer-Policy "strict-origin-when-cross-origin"

        # Development indicators
        X-CME-Environment "development"
        X-Powered-By "FrankenWP/CME-Dev"
    }

    # Handle cache purging
    handle /__cache/purge* {
        # This will be handled by FrankenWP's built-in cache purge
        respond 200
    }

    # Handle WordPress
    handle {
        root * /var/www/html
        php_fastcgi unix//run/php/php8.3-fpm.sock
        file_server
    }
}
EOF

    # Create plugin installation script
    cat > "${PROJECT_DIR}/services/wordpress/setup-scripts/install-plugins.sh" << 'EOF'
#!/bin/bash

# CME WordPress Plugin Installation Script
# Installs and configures plugins specific to CME functionality

echo "Installing CME-specific WordPress plugins..."

# Essential plugins for CME
PLUGINS=(
    "contact-form-7"          # Contact forms
    "wp-fastest-cache"        # Caching (works with FrankenWP)
    "wordfence"              # Security
    "matomo"                 # Analytics integration
    "wp-super-cache"         # Additional caching options
    "yoast-seo"              # SEO optimization
    "wp-mail-smtp"           # Email configuration
)

# Install plugins if WP-CLI is available
if command -v wp >/dev/null 2>&1; then
    for plugin in "${PLUGINS[@]}"; do
        echo "Installing $plugin..."
        wp plugin install "$plugin" --allow-root --quiet || echo "Failed to install $plugin"
    done

    # Activate essential plugins
    echo "Activating essential plugins..."
    wp plugin activate contact-form-7 --allow-root --quiet || echo "Failed to activate contact-form-7"
    wp plugin activate matomo --allow-root --quiet || echo "Failed to activate matomo"
    wp plugin activate wp-fastest-cache --allow-root --quiet || echo "Failed to activate wp-fastest-cache"

    echo "Plugin installation completed"
else
    echo "WP-CLI not available, skipping plugin installation"
fi

# Create custom CME plugin directory
mkdir -p /var/www/html/wp-content/plugins/cme-core
cat > /var/www/html/wp-content/plugins/cme-core/cme-core.php << 'PLUGIN_EOF'
<?php
/**
 * Plugin Name: CME Core Functionality
 * Description: Core functionality for Cruise Made Easy website
 * Version: 1.0.0-dev
 * Author: CME Development Team
 */

// Prevent direct access
if (!defined('ABSPATH')) {
    exit;
}

// Define CME constants
define('CME_PLUGIN_VERSION', '1.0.0-dev');
define('CME_PLUGIN_DIR', plugin_dir_path(__FILE__));
define('CME_PLUGIN_URL', plugin_dir_url(__FILE__));

// Initialize CME functionality
add_action('init', 'cme_init');

function cme_init() {
    // Add CME-specific functionality here

    // Add custom body classes for persona detection
    add_filter('body_class', 'cme_add_persona_body_classes');

    // Enqueue CME scripts and styles
    add_action('wp_enqueue_scripts', 'cme_enqueue_assets');
}

function cme_add_persona_body_classes($classes) {
    // Add persona-based classes for styling
    $persona = get_user_meta(get_current_user_id(), 'cme_persona', true);
    if ($persona) {
        $classes[] = 'cme-persona-' . sanitize_html_class($persona);
    }

    $classes[] = 'cme-environment-' . CME_ENVIRONMENT;
    return $classes;
}

function cme_enqueue_assets() {
    // Enqueue CME-specific JavaScript and CSS
    wp_enqueue_script('cme-core', CME_PLUGIN_URL . 'assets/cme-core.js', ['jquery'], CME_PLUGIN_VERSION, true);
    wp_enqueue_style('cme-core', CME_PLUGIN_URL . 'assets/cme-core.css', [], CME_PLUGIN_VERSION);

    // Localize script with CME configuration
    wp_localize_script('cme-core', 'cme_config', [
        'ajax_url' => admin_url('admin-ajax.php'),
        'nonce' => wp_create_nonce('cme_nonce'),
        'matomo_url' => defined('MATOMO_URL') ? MATOMO_URL : '',
        'environment' => CME_ENVIRONMENT,
    ]);
}
PLUGIN_EOF

    # Create assets directory for CME plugin
    mkdir -p /var/www/html/wp-content/plugins/cme-core/assets

    # Create basic CME JavaScript
    cat > /var/www/html/wp-content/plugins/cme-core/assets/cme-core.js << 'JS_EOF'
// CME Core JavaScript
(function($) {
    'use strict';

    $(document).ready(function() {
        console.log('CME Core initialized in ' + cme_config.environment + ' environment');

        // Initialize persona detection
        CME.persona.init();

        // Initialize analytics
        if (cme_config.matomo_url) {
            CME.analytics.init();
        }
    });

    // CME namespace
    window.CME = window.CME || {};

    // Persona functionality
    CME.persona = {
        init: function() {
            console.log('CME Persona system initialized');
            // Add persona detection logic here
        }
    };

    // Analytics functionality
    CME.analytics = {
        init: function() {
            console.log('CME Analytics initialized');
            // Add analytics integration here
        }
    };

})(jQuery);
JS_EOF

    # Create basic CME CSS
    cat > /var/www/html/wp-content/plugins/cme-core/assets/cme-core.css << 'CSS_EOF'
/* CME Core Styles */

/* Development environment indicator */
.cme-environment-development::before {
    content: "DEV";
    position: fixed;
    top: 0;
    right: 0;
    background: #ff6b35;
    color: white;
    padding: 5px 10px;
    font-size: 12px;
    font-weight: bold;
    z-index: 9999;
    font-family: monospace;
}

/* Persona-based styling */
.cme-persona-luxury-seeker {
    --cme-primary-color: #8b7355;
    --cme-accent-color: #d4af37;
}

.cme-persona-adventure-explorer {
    --cme-primary-color: #2d5a27;
    --cme-accent-color: #ff6b35;
}

.cme-persona-budget-conscious-family {
    --cme-primary-color: #1e4d72;
    --cme-accent-color: #28a745;
}

/* CME component styling */
.cme-quiz-container {
    border: 2px solid var(--cme-primary-color, #333);
    border-radius: 8px;
    padding: 20px;
    margin: 20px 0;
}

.cme-persona-result {
    background: var(--cme-accent-color, #007cba);
    color: white;
    padding: 15px;
    border-radius: 5px;
    text-align: center;
}
CSS_EOF

    echo "CME plugin setup completed"
EOF

    chmod +x "${PROJECT_DIR}/services/wordpress/setup-scripts/install-plugins.sh"

    # Set proper permissions
    find "${PROJECT_DIR}/services/wordpress/wp-content" -type d -exec chmod 755 {} \;
    find "${PROJECT_DIR}/services/wordpress/wp-content" -type f -exec chmod 644 {} \;

    info "FrankenWP directory structure created"
    info "WordPress content directory: ${PROJECT_DIR}/services/wordpress/wp-content"
    info "Custom wp-config.php: ${PROJECT_DIR}/services/wordpress/root-files/wp-config.php"
    info "Setup scripts: ${PROJECT_DIR}/services/wordpress/setup-scripts/"
}

show_frankenwp_info() {
    log "FrankenWP Configuration Summary"
    echo ""
    echo "Key Differences from Standard WordPress:"
    echo "• Uses Caddy web server instead of Apache/Nginx"
    echo "• Built-in caching with configurable TTL"
    echo "• Environment-based configuration via env vars"
    echo "• No need for separate reverse proxy"
    echo ""
    echo "Important Environment Variables:"
    echo "• SERVER_NAME: :80 (listens on all interfaces)"
    echo "• CACHE_LOC: /var/www/html/wp-content/cache"
    echo "• TTL: 80000 (cache time-to-live in seconds)"
    echo "• PURGE_PATH: /__cache/purge (cache invalidation endpoint)"
    echo "• BYPASS_PATH_PREFIXES: paths to exclude from caching"
    echo ""
    echo "Cache Management:"
    echo "• Cache purge URL: https://dev-wordpress.cme.ksstorm.dev/__cache/purge"
    echo "• Requires PURGE_KEY for authentication"
    echo "• Bypasses admin, content, and API paths automatically"
    echo ""
    echo "Next Steps:"
    echo "1. Run: ./scripts/generate-dev-secrets.sh"
    echo "2. Run: ./scripts/compose-dev.sh start wordpress"
    echo "3. Configure WordPress via web interface"
    echo "4. Install CME-specific themes and plugins"
}

main() {
    echo -e "${GREEN}"
    echo "================================================================"
    echo "  FrankenWP Setup for CME Development"
    echo "================================================================"
    echo -e "${NC}"

    create_frankenwp_structure
    show_frankenwp_info
}

main "$@"
