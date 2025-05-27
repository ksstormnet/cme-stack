# CME Stack Development Setup

> Complete guide for setting up the Cruise Made Easy development environment

## Prerequisites

### Required Software

- **Docker Desktop 4.0+** or **Docker Engine 20.10+**
- **Docker Compose v2** (included with Docker Desktop)
- **Git 2.30+**
- **1Password CLI** (for secrets management)
- **Text Editor/IDE** with Docker and YAML support

### System Requirements

- **Memory**: 8GB RAM minimum, 16GB recommended
- **Storage**: 10GB free space for containers and volumes
- **Network**: Reliable internet for image downloads and external service connections

### External Dependencies

Before starting the CME stack, ensure these external services are available:

- **MariaDB Server** - Database server accessible from Docker containers
- **Redis Server** - Cache and session storage accessible from Docker containers
- **Reverse Proxy** - SSL-terminating proxy (Zoraxy, nginx, Caddy, etc.)
- **DNS Configuration** - Subdomain routing for service access

## Environment Setup

### 1. Repository Setup

```bash
# Clone the repository
git clone <repository-url>
cd cme-stack

# Verify project structure
ls -la
# Should show: docker-compose.*.yml, services/, scripts/, docs/
```

### 2. Secrets Generation

The CME stack uses a **template-based secrets system** that keeps all actual credentials out of the repository while providing clear structure for configuration.

```bash
# Generate development secrets from templates
./scripts/generate-dev-secrets.sh

# This script will:
# - Prompt for external service configuration (MariaDB, Redis, SMTP)
# - Generate secure random passwords and keys for all services
# - Create .env files from .env.template files with real values
# - Output SQL commands for database setup
# - Display admin credentials for all services
# - Backup any existing .env files before generating new ones
```

**Security Features**:
- **Templates in Repo**: `.env.template` files show structure but contain no real secrets
- **Generated Files Ignored**: All `.env` files are automatically ignored by git
- **Secure Generation**: Uses OpenSSL for cryptographically secure password generation
- **Backup Protection**: Existing .env files are backed up before regeneration
- **No Hardcoded Secrets**: All credentials are generated fresh each time

**Important**: 
- Save the admin credentials displayed by the script - they won't be shown again
- The SQL commands must be run on your MariaDB server to create databases and users
- All `.env` files are ignored by git and will never be committed accidentally

### 3. Database Setup

Using the SQL commands output by the secrets script, create the required databases:

```sql
-- Run these commands on your MariaDB server
-- (Replace with actual commands from secrets script output)

CREATE DATABASE cme_wordpress;
CREATE DATABASE cme_matomo;
CREATE DATABASE cme_n8n;
CREATE DATABASE cme_glitchtip;
CREATE DATABASE cme_gitlab;

-- Create service users with appropriate permissions
-- (User creation commands provided by secrets script)
```

### 4. Network Configuration

The CME stack uses custom Docker networks for service isolation:

```bash
# Networks are created automatically by Docker Compose, but you can verify:
docker network ls | grep cme

# Expected networks:
# cme-frontend    - WordPress, Matomo, n8n
# cme-backend     - Internal service communication
# cme-monitoring  - Prometheus, Grafana, Loki
```

### 5. Service Directory Structure

Each service has its own configuration directory with template and generated files:

```
services/
├── wordpress/
│   ├── .env.template     # Configuration template (in repo)
│   ├── .env              # Generated environment (ignored by git)
│   ├── wp-config.php     # WordPress configuration
│   └── themes/           # Custom theme development
├── matomo/
│   ├── .env.template     # Configuration template (in repo)
│   ├── .env              # Generated environment (ignored by git)
│   └── config/           # Matomo configuration files
├── n8n/
│   ├── .env.template     # Configuration template (in repo)
│   ├── .env              # Generated environment (ignored by git)
│   └── workflows/        # Custom workflow definitions
├── glitchtip/
│   ├── .env.template     # Configuration template (in repo)
│   ├── .env              # Generated environment (ignored by git)
│   └── config/           # Error tracking configuration
├── gitlab/
│   ├── .env.template     # Configuration template (in repo)
│   ├── .env              # Generated environment (ignored by git)
│   └── config/           # GitLab CI/CD configuration
├── prometheus/
│   ├── .env.template     # Configuration template (in repo)
│   ├── prometheus.yml    # Metrics collection configuration
│   └── rules/           # Alerting rules
├── grafana/
│   ├── .env.template     # Configuration template (in repo)
│   ├── .env              # Generated environment (ignored by git)
│   ├── dashboards/      # Custom dashboard definitions
│   └── provisioning/    # Grafana provisioning configs
└── loki/
    └── loki.yml         # Log aggregation configuration
```

**Template System**:
- **`.env.template`** files are committed to the repository and show configuration structure
- **`.env`** files are generated locally and contain actual secrets (never committed)
- **Backup Protection**: Script automatically backs up existing .env files before regeneration

## Development Environments

The CME stack supports multiple development configurations:

### Core Development Environment

**Purpose**: Essential services for WordPress development and basic testing
**Services**: WordPress, Matomo, n8n
**Use Case**: Frontend development, content creation, workflow testing

```bash
# Start core development environment
./scripts/compose-dev.sh dev

# Services available:
# - WordPress: https://dev-wordpress.cme.ksstorm.dev
# - Matomo: https://dev-matomo.cme.ksstorm.dev  
# - n8n: https://dev-n8n.cme.ksstorm.dev
```

### Full Development Environment

**Purpose**: Complete development stack with all services
**Services**: All core services + GitLab + GlitchTip + monitoring
**Use Case**: Full-stack development, integration testing, CI/CD development

```bash
# Start all development services
./scripts/compose-dev.sh start core
./scripts/compose-dev.sh start infrastructure
./scripts/compose-dev.sh start monitoring

# Additional services available:
# - GitLab: https://dev-gitlab.cme.ksstorm.dev
# - GlitchTip: https://dev-glitchtip.cme.ksstorm.dev
# - Grafana: https://dev-grafana.cme.ksstorm.dev
```

### Staging-Like Environment

**Purpose**: Production-like configuration for pre-deployment testing
**Services**: All services with production-like settings
**Use Case**: Final testing before production deployment

```bash
# Start staging-like environment
./scripts/compose-dev.sh staging

# Uses staging configurations:
# - Production-like resource limits
# - Monitoring and alerting enabled
# - Security configurations active
```

## Service Management

### Starting Services

```bash
# Start specific service groups
./scripts/compose-dev.sh start core          # WordPress, Matomo, n8n
./scripts/compose-dev.sh start infrastructure # GitLab, GlitchTip
./scripts/compose-dev.sh start monitoring    # Prometheus, Grafana, Loki

# Start individual services
docker compose -f docker-compose.core.yml up wordpress -d
docker compose -f docker-compose.infrastructure.yml up gitlab -d
```

### Monitoring Services

```bash
# Check health of all services
./scripts/compose-dev.sh health

# View logs for specific services
./scripts/compose-dev.sh logs wordpress
./scripts/compose-dev.sh logs n8n

# Monitor resource usage
docker stats

# View service status
docker compose -f docker-compose.core.yml ps
```

### Stopping Services

```bash
# Clean shutdown of all services
./scripts/compose-dev.sh down

# Stop specific service groups
docker compose -f docker-compose.core.yml down
docker compose -f docker-compose.monitoring.yml down

# Emergency stop (force kill)
docker compose -f docker-compose.core.yml kill
```

## Development Workflow

### File Mounting and Live Development

Development environments include volume mounts for live file editing:

```yaml
# WordPress development
services/wordpress/themes/     -> Container: /var/www/html/wp-content/themes/
services/wordpress/plugins/    -> Container: /var/www/html/wp-content/plugins/

# n8n workflow development  
services/n8n/workflows/       -> Container: /home/node/.n8n/workflows/

# Configuration development
services/*/config/            -> Container: /app/config/ (service-specific)
```

### Database Access

```bash
# Connect to service databases
docker exec -it cme-mariadb mysql -u cme_wordpress -p cme_wordpress
docker exec -it cme-mariadb mysql -u cme_matomo -p cme_matomo

# Redis access
docker exec -it cme-redis redis-cli

# Database backups
docker exec cme-mariadb mysqldump -u root -p cme_wordpress > wordpress-backup.sql
```

### Log Management

```bash
# Service-specific logs
docker compose -f docker-compose.core.yml logs -f wordpress
docker compose -f docker-compose.core.yml logs -f matomo
docker compose -f docker-compose.infrastructure.yml logs -f n8n

# Aggregated logging (when Loki is running)
# Access via Grafana -> Explore -> Loki data source

# Log file locations
docker exec -it cme-wordpress ls -la /var/log/
docker exec -it cme-n8n ls -la /home/node/.n8n/logs/
```

## Troubleshooting

### Common Issues

#### Services Not Starting

```bash
# Check Docker daemon status
docker version
docker compose version

# Check resource usage
docker system df
docker system prune  # Clean up if needed

# Verify network connectivity
docker network ls
docker network inspect cme-frontend
```

#### Database Connection Issues

```bash
# Test database connectivity from containers
docker exec -it cme-wordpress ping mariadb-host
docker exec -it cme-wordpress nc -zv mariadb-host 3306

# Verify database credentials
docker exec -it cme-wordpress env | grep DB_
```

#### Service Health Check Failures

```bash
# Check individual service health
docker inspect cme-wordpress | grep -A 10 Health
curl -f http://localhost:8080/health  # Direct health check

# Review service logs for errors
docker logs cme-wordpress --tail 50
docker logs cme-n8n --tail 50
```

### Performance Issues

#### Resource Monitoring

```bash
# Monitor container resource usage
docker stats

# Check system resources
free -h
df -h
iostat -x 1

# Optimize Docker resource allocation
# Docker Desktop: Settings -> Resources -> Advanced
```

#### Service Optimization

```bash
# WordPress performance
# - Enable object caching (Redis)
# - Optimize database queries
# - Configure Caddy caching

# n8n performance  
# - Monitor workflow execution times
# - Optimize webhook response times
# - Review queue processing

# Database performance
# - Monitor slow query log
# - Review connection pool settings
# - Optimize MariaDB configuration
```

### Development Tools

#### Useful Commands

```bash
# Container shell access
docker exec -it cme-wordpress bash
docker exec -it cme-n8n sh
docker exec -it cme-gitlab bash

# File operations
docker cp local-file.txt cme-wordpress:/var/www/html/
docker cp cme-wordpress:/var/www/html/wp-config.php ./

# Network debugging
docker exec -it cme-wordpress nslookup matomo
docker exec -it cme-n8n curl -I http://wordpress/wp-admin/
```

#### Development Extensions

Recommended tools for CME stack development:

- **VS Code Extensions**:
  - Docker (Microsoft)
  - YAML (Red Hat)
  - PHP (DEVSENSE) - for WordPress development
  - GitLens - for Git integration

- **Browser Extensions**:
  - Docker Dashboard
  - Matomo Tag Manager (for analytics testing)
  - Web Developer Tools

## Next Steps

After completing development setup:

1. **Verify Service Access** - Test all service URLs and basic functionality
2. **Configure Integrations** - Set up external API connections (GoHighLevel, OpenAI, etc.)
3. **Import Sample Data** - Load test data for development and testing
4. **Review Monitoring** - Configure Grafana dashboards and Prometheus alerts
5. **Test Workflows** - Verify n8n automation and integrations work correctly

## Additional Resources

- **[Architecture Overview](docs/ARCHITECTURE.md)** - Detailed service interactions and technical decisions
- **[Deployment Guide](docs/DEPLOYMENT.md)** - Production deployment procedures
- **Service Documentation**:
  - [WordPress Development](services/wordpress/README.md)
  - [n8n Workflow Development](services/n8n/README.md)
  - [Monitoring Setup](services/prometheus/README.md)

---

**Questions or Issues?** Check the troubleshooting section above or review service-specific logs for detailed error information.