# CME Stack - Cruise Made Easy

> Privacy-focused, self-hosted marketing automation stack with modular Docker architecture

[![Docker](https://img.shields.io/badge/Docker-20.10+-blue)](https://www.docker.com/)
[![Status](https://img.shields.io/badge/Status-Development-yellow)](https://github.com/yourusername/cme-stack)

## 🚢 Overview

Cruise Made Easy (CME) is a comprehensive, privacy-focused marketing automation stack designed for travel agencies. Built with a modular Docker Compose architecture, it provides complete infrastructure for customer journey management from initial engagement through automated nurturing and scheduling.

### Key Features

- **Privacy-First Analytics** - Self-hosted Matomo with complete visitor data ownership
- **Modular Architecture** - Scalable Docker Compose services with clear separation of concerns
- **WordPress Integration** - FrankenWP with built-in caching and performance optimization
- **Workflow Automation** - n8n orchestrating multi-system integrations
- **Complete Observability** - Prometheus, Grafana, and Loki monitoring stack
- **Error Tracking** - GlitchTip for comprehensive exception monitoring
- **Development-Focused** - Local GitLab with full CI/CD capabilities
- **Secrets Management** - Service-specific secure credential handling

## 🏗️ Architecture

The CME stack is built using **five modular Docker Compose configurations** that can be deployed independently or together based on environment needs:

### Compose Configurations

| Configuration                         | Purpose                            | Primary Services                  | Typical Use                          |
| ------------------------------------- | ---------------------------------- | --------------------------------- | ------------------------------------ |
| **docker-compose.base.yml**           | Shared networks, volumes, patterns | Networks, volumes, common configs | Foundation for all environments      |
| **docker-compose.frontend.yml**       | Essential business services        | WordPress, Matomo, n8n            | Core development, minimal production |
| **docker-compose.infrastructure.yml** | Development & operations           | GitLab, GlitchTip, tools          | Full development environment         |
| **docker-compose.monitoring.yml**     | Observability stack                | Prometheus, Grafana, Loki         | Production monitoring                |
| **docker-compose.dev.yml**            | Development orchestration          | All services + dev overrides      | Complete development environment     |

### Core Services

| Service        | Purpose                            | Technology            | External Access   |
| -------------- | ---------------------------------- | --------------------- | ----------------- |
| **WordPress**  | Content management & lead capture  | FrankenWP + Caddy     | Via reverse proxy |
| **Matomo**     | Privacy-focused visitor analytics  | Matomo 4.15 + MariaDB | Via reverse proxy |
| **n8n**        | Workflow automation & integrations | n8n 1.17.1            | Via reverse proxy |
| **GlitchTip**  | Error tracking & monitoring        | Sentry-compatible     | Via reverse proxy |
| **GitLab**     | Source control & CI/CD             | GitLab CE             | Via reverse proxy |
| **Grafana**    | Dashboards & visualization         | Grafana 10.2.3        | Via reverse proxy |
| **Prometheus** | Metrics collection                 | Prometheus 2.48.1     | Internal network  |
| **Loki**       | Log aggregation                    | Grafana Loki          | Internal network  |

### External Dependencies

- **MariaDB** - Primary data storage (existing external service)
- **Redis** - Caching & session management (existing external service)
- **Reverse Proxy** - SSL termination and routing (Zoraxy or similar)

### External Integrations

- **GoHighLevel** - Marketing automation & calendar scheduling
- **TravelJoy** - Final customer management & quoting (CSV import)
- **OpenAI API** - LLM inference for conversational features
- **Voip.ms** - Voice & SMS services

## 🚀 Quick Start

### Prerequisites

- Docker 20.10+ and Docker Compose v2
- External MariaDB and Redis instances
- Reverse proxy with SSL termination

### Development Setup

```bash
# 1. Clone repository
git clone <repository-url>
cd cme-stack

# 2. Generate development secrets from templates
./scripts/generate-dev-secrets.sh

# 3. Setup database schemas
# (Run SQL commands output by secrets script on your MariaDB server)

# 4. Start development environment (choose one option):

# Option A: Complete development environment
docker-compose -f docker-compose.dev.yml up -d

# Option B: Core services only
docker-compose -f docker-compose.frontend.yml up -d

# Option C: Step-by-step service groups
docker-compose -f docker-compose.frontend.yml up -d      # WordPress, Matomo, n8n
docker-compose -f docker-compose.infrastructure.yml up -d # GitLab, GlitchTip
docker-compose -f docker-compose.monitoring.yml up -d     # Monitoring stack
```

### Service Management

```bash
# Health check all services
docker-compose -f docker-compose.dev.yml ps

# View service logs
docker-compose -f docker-compose.frontend.yml logs -f wordpress
docker-compose -f docker-compose.infrastructure.yml logs -f n8n

# Stop all services
docker-compose -f docker-compose.dev.yml down

# Start with optional tools (Adminer, Redis Commander)
docker-compose -f docker-compose.dev.yml --profile tools up -d

# Start with extended monitoring (cAdvisor, AlertManager)
docker-compose -f docker-compose.monitoring.yml --profile monitoring-extended up -d
```

### Service Access

Services are accessed through reverse proxy with environment-specific domains:

**Development:**

- **WordPress**: `https://dev-wordpress.cme.ksstorm.dev`
- **Matomo**: `https://dev-matomo.cme.ksstorm.dev`
- **n8n**: `https://dev-n8n.cme.ksstorm.dev`
- **GitLab**: `https://dev-gitlab.cme.ksstorm.dev`
- **GlitchTip**: `https://dev-glitchtip.cme.ksstorm.dev`
- **Grafana**: `https://dev-grafana.cme.ksstorm.dev`

**Development Tools** (with `--profile tools`):

- **MailHog**: `http://localhost:50025`
- **Adminer**: `https://dev-adminer.cme.ksstorm.dev`
- **Redis Commander**: `https://dev-redis-commander.cme.ksstorm.dev`

**Production:**

- **WordPress**: `https://cruisemadeeasy.com`
- **Matomo**: `https://analytics.cruisemadeeasy.com`
- **n8n**: `https://automation.cruisemadeeasy.com`
- **Grafana**: `https://monitoring.cruisemadeeasy.com`

## 📁 Project Structure

```
cme-stack/
├── docker-compose.*.yml         # Modular compose configurations
├── services/                    # Service-specific configurations
│   ├── wordpress/              # FrankenWP configuration + .env.template
│   ├── matomo/                 # Analytics setup + .env.template
│   ├── n8n/                    # Workflow automation + .env.template
│   ├── glitchtip/             # Error tracking + .env.template
│   ├── gitlab/                 # CI/CD configuration + .env.template
│   ├── prometheus/             # Metrics collection + configs
│   ├── grafana/               # Dashboard configs + .env.template
│   └── loki/                  # Log aggregation + configs
├── scripts/                    # Management and deployment
│   ├── generate-dev-secrets.sh # Service-specific secret generation
│   └── compose-dev.sh         # Development orchestration (deprecated)
├── docs/                      # Technical documentation
│   ├── ARCHITECTURE.md        # Detailed technical architecture
│   └── DEPLOYMENT.md          # Deployment procedures
└── DEVELOPMENT-SETUP.md       # Complete setup guide
```

## 🔧 Development Workflow

### Environment Management

The CME stack supports flexible development configurations:

- **Frontend Only** - Core business services for rapid development
- **Full Development** - All services including CI/CD and monitoring
- **Production-like** - Complete stack with production configurations

### Credential Management

**Security-First Design:**

- **Service-specific** `.env` files generated from templates
- **Never commit** actual credentials (all `.env` files ignored by git)
- **Template system** shows configuration structure without exposing secrets
- **Cryptographically secure** password generation

```bash
# Generate fresh credentials anytime
./scripts/generate-dev-secrets.sh

# Templates show structure, .env files contain real values
services/wordpress/.env.template  # ← In git (template)
services/wordpress/.env           # ← Generated locally (ignored by git)
```

### Service Configuration

Each service maintains its own configuration:

```bash
# Service-specific environment files
services/wordpress/.env          # WordPress database, Redis, API keys
services/matomo/.env            # Analytics database and admin credentials
services/n8n/.env               # Automation database, API keys, encryption
services/glitchtip/.env         # Error tracking database, Redis, SMTP
services/gitlab/.env            # CI/CD database, Redis, admin credentials
services/grafana/.env           # Monitoring database, admin credentials
```

### Network Architecture

- **cme-dev** - Internal service communication (development)
- **cme-monitoring** - Monitoring stack communication
- **external** - Reverse proxy integration (shared across environments)

Services communicate via Docker DNS (e.g., `dev-wordpress`, `dev-matomo`).

### Git Branching Strategy

- **main** - Production-ready code, deployed via GitHub Actions to production
- **staging** - Pre-production testing, deployed to staging environment
- **dev** - Active development integration, continuous deployment to dev
- **feature/\*** - Feature development branches
- **chore/\*** - Infrastructure and maintenance tasks

## 📊 Monitoring & Observability

### Metrics Collection

- **Business Metrics** - Visitor conversion rates, booking pipeline, revenue attribution
- **System Metrics** - Container resources, database performance, API response times
- **Application Metrics** - WordPress performance, n8n workflow success rates
- **Infrastructure Metrics** - Network throughput, storage utilization, service health

### Error Tracking & Logging

- **GlitchTip** - Centralized exception tracking across all services
- **Loki** - Structured log aggregation with label-based querying
- **Service Logs** - Individual service logging with consistent formatting

### Dashboard Access

- **Grafana**: Primary dashboard interface for all metrics visualization
- **Prometheus**: Direct access to metrics and alerting rules
- **GlitchTip**: Error tracking and performance monitoring

## 🔐 Security & Privacy

### Privacy Compliance

- **GDPR/CCPA Compliant** - Complete visitor data ownership through self-hosted analytics
- **No Third-Party Tracking** - All analytics and monitoring remain within infrastructure
- **Data Residency** - Full control over data location and retention policies

### Security Architecture

- **Network Isolation** - Services communicate through defined Docker networks
- **Secrets Management** - Service-specific credential isolation
- **SSL Termination** - Reverse proxy handles all external SSL/TLS
- **Principle of Least Privilege** - Services only access required resources

### Redis Database Isolation

- **WordPress**: Database 12 (object cache, sessions)
- **GlitchTip**: Database 13 (Celery worker queue)
- **GitLab**: Database 14 (cache, queues)

## 🚀 Deployment Options

### Development Deployment

```bash
# Quick development start
docker-compose -f docker-compose.dev.yml up -d

# Service-specific development
docker-compose -f docker-compose.frontend.yml up -d
docker-compose -f docker-compose.infrastructure.yml up -d
docker-compose -f docker-compose.monitoring.yml up -d

# With development tools
docker-compose -f docker-compose.dev.yml --profile tools up -d

# Health check validation
docker-compose -f docker-compose.dev.yml --profile healthcheck up dev-healthcheck
```

### Production Deployment (Planned)

```bash
# Production deployment will use GitHub Actions
# Staging deployment uses GitLab CI/CD
# See docs/DEPLOYMENT.md for complete procedures
```

## 🤝 Development Process

### Implementation Workflow

1. **Branch Creation** - Create feature/chore branch from `dev`
2. **Secret Generation** - Generate development credentials
3. **Service Development** - Develop with live file mounting in dev environment
4. **Integration Testing** - Test service interactions and data flows
5. **Health Validation** - Run health checks and monitoring verification
6. **Documentation Updates** - Update relevant documentation for changes
7. **Staging Deployment** - Deploy to staging for pre-production testing
8. **Production Release** - Merge to main and deploy to production

### Quality Standards

- **Configuration Completeness** - All Docker Compose services include comprehensive configuration
- **Health Monitoring** - All services provide health check endpoints
- **Documentation Currency** - Changes include corresponding documentation updates
- **Security Review** - All configurations follow security best practices
- **Environment Parity** - Configurations work consistently across dev/staging/production

## 📚 Documentation

- **[Development Setup](DEVELOPMENT-SETUP.md)** - Complete environment setup instructions
- **[Architecture Overview](docs/ARCHITECTURE.md)** - Detailed technical architecture and service interactions
- **[Deployment Guide](docs/DEPLOYMENT.md)** - Production deployment procedures and workflows

## 🔧 Troubleshooting

### Common Issues

```bash
# Service won't start - check credentials
docker-compose -f docker-compose.frontend.yml logs wordpress

# Network connectivity issues
docker exec dev-wordpress ping dev-matomo

# Database connection problems
docker exec dev-wordpress nc -zv mariadb-host 3306

# Redis connection issues
docker exec dev-wordpress nc -zv redis-host 6379

# Generate fresh credentials
./scripts/generate-dev-secrets.sh
```

### Health Checks

```bash
# Check all service health
docker-compose -f docker-compose.dev.yml ps

# Individual service health
curl -f https://dev-wordpress.cme.ksstorm.dev/wp-admin/admin-ajax.php
curl -f https://dev-n8n.cme.ksstorm.dev/healthz
curl -f https://dev-grafana.cme.ksstorm.dev/api/health
```

## 📄 License

This project is proprietary software developed for Cruise Made Easy operations. All rights reserved.

---

**Cruise Made Easy** - Privacy-focused marketing automation for the modern travel agency.
