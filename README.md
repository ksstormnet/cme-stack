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
- **Secrets Management** - 1Password Connect integration for secure credential handling

## 🏗️ Architecture

The CME stack is built using **five modular Docker Compose configurations** that can be deployed independently or together based on environment needs:

### Compose Configurations

| Configuration | Purpose | Primary Services | Typical Use |
|---------------|---------|------------------|-------------|
| **docker-compose.core.yml** | Essential business services | WordPress, Matomo, n8n | Development, minimal production |
| **docker-compose.infrastructure.yml** | Development & operations | GitLab, GlitchTip, tools | Full development environment |
| **docker-compose.monitoring.yml** | Observability stack | Prometheus, Grafana, Loki | Production monitoring |
| **docker-compose.dev.yml** | Development overrides | Volume mounts, debug configs | Local development |
| **docker-compose.staging.yml** | Staging environment | Production-like configs | Pre-production testing |

### Core Services

| Service | Purpose | Technology | External Access |
|---------|---------|------------|-----------------|
| **WordPress** | Content management & lead capture | FrankenWP + Caddy | Via reverse proxy |
| **Matomo** | Privacy-focused visitor analytics | Matomo 4.15 + MariaDB | Via reverse proxy |
| **n8n** | Workflow automation & integrations | n8n 1.17.1 | Via reverse proxy |
| **GlitchTip** | Error tracking & monitoring | Sentry-compatible | Via reverse proxy |
| **GitLab** | Source control & CI/CD | GitLab CE | Via reverse proxy |
| **Grafana** | Dashboards & visualization | Grafana 10.2.3 | Via reverse proxy |
| **Prometheus** | Metrics collection | Prometheus 2.48.1 | Internal network |
| **Loki** | Log aggregation | Grafana Loki | Internal network |

### External Dependencies

- **MariaDB** - Primary data storage (existing external service)
- **Redis** - Caching & session management (existing external service)  
- **Reverse Proxy** - SSL termination and routing (Zoraxy or similar)
- **1Password Connect** - Secrets management (planned integration)

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
- 1Password CLI (for secrets management)

### Development Setup

```bash
# 1. Clone repository
git clone <repository-url>
cd cme-stack

# 2. Generate development secrets
./scripts/generate-dev-secrets.sh

# 3. Setup database schemas
# (Run SQL commands output by secrets script)

# 4. Start core development services
./scripts/compose-dev.sh dev

# 5. Start additional services as needed
./scripts/compose-dev.sh start infrastructure  # GitLab, GlitchTip
./scripts/compose-dev.sh start monitoring     # Full observability
```

### Service Access

Services are accessed through reverse proxy with environment-specific domains:

**Development:**
- **WordPress**: `https://dev-wordpress.cme.ksstorm.dev`
- **Matomo**: `https://dev-matomo.cme.ksstorm.dev`
- **n8n**: `https://dev-n8n.cme.ksstorm.dev`
- **GitLab**: `https://dev-gitlab.cme.ksstorm.dev`
- **Grafana**: `https://dev-grafana.cme.ksstorm.dev`

**Staging:**
- **WordPress**: `https://staging-wordpress.cme.ksstorm.dev`
- **Matomo**: `https://staging-matomo.cme.ksstorm.dev`
- **n8n**: `https://staging-n8n.cme.ksstorm.dev`
- **Grafana**: `https://staging-grafana.cme.ksstorm.dev`

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
│   ├── wordpress/              # FrankenWP configuration
│   ├── matomo/                 # Analytics setup
│   ├── n8n/                    # Workflow automation
│   ├── glitchtip/             # Error tracking
│   ├── gitlab/                 # CI/CD configuration
│   ├── prometheus/             # Metrics collection
│   ├── grafana/               # Dashboard configs
│   └── loki/                  # Log aggregation
├── scripts/                    # Management and deployment
│   ├── compose-dev.sh         # Development orchestration
│   ├── generate-dev-secrets.sh # Secret generation
│   └── health-check.sh        # Service health validation
├── docs/                      # Technical documentation
│   ├── ARCHITECTURE.md        # Detailed technical architecture
│   └── DEPLOYMENT.md          # Deployment procedures
└── DEVELOPMENT-SETUP.md       # Complete setup guide
```

## 🔧 Development Workflow

### Environment Management

The CME stack supports three primary environments with different service configurations:

- **Development** - Core services with file mounting and debug configurations
- **Staging** - Production-like configuration for pre-deployment testing  
- **Production** - Full service stack with monitoring and high availability

### Service Management Commands

```bash
# Core development environment
./scripts/compose-dev.sh dev                 # Start core services only
./scripts/compose-dev.sh staging             # Staging-like environment

# Service group management
./scripts/compose-dev.sh start core          # WordPress, Matomo, n8n
./scripts/compose-dev.sh start infrastructure # GitLab, GlitchTip
./scripts/compose-dev.sh start monitoring    # Prometheus, Grafana, Loki

# Monitoring and debugging
./scripts/compose-dev.sh logs [service]      # View service logs
./scripts/compose-dev.sh health              # Health check all services
./scripts/compose-dev.sh down               # Clean shutdown
```

### Git Branching Strategy

- **main** - Production-ready code, deployed via GitHub Actions to production
- **staging** - Pre-production testing, deployed to staging environment
- **dev** - Active development integration, continuous deployment to dev
- **feature/*** - Feature development branches
- **chore/*** - Infrastructure and maintenance tasks

### Source Control Strategy

- **GitHub** - Primary repository hosting with GitHub Actions for production CI/CD
- **GitLab (Development Only)** - Local development GitLab for CI/CD pipeline development and testing
- **Deployment Flow** - GitLab CI/CD handles staging deployments, GitHub Actions handles production

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
- **Secrets Management** - 1Password Connect integration for credential security
- **SSL Termination** - Reverse proxy handles all external SSL/TLS
- **Principle of Least Privilege** - Services only access required resources

## 📚 Documentation

- **[Development Setup](DEVELOPMENT-SETUP.md)** - Complete environment setup instructions
- **[Architecture Overview](docs/ARCHITECTURE.md)** - Detailed technical architecture and service interactions
- **[Deployment Guide](docs/DEPLOYMENT.md)** - Production deployment procedures and workflows

## 🤝 Development Process

### Implementation Workflow

1. **Branch Creation** - Create feature/chore branch from `dev`
2. **Service Development** - Develop with live file mounting in dev environment
3. **Integration Testing** - Test service interactions and data flows
4. **Health Validation** - Run health checks and monitoring verification
5. **Documentation Updates** - Update relevant documentation for changes
6. **Staging Deployment** - Deploy to staging for pre-production testing
7. **Production Release** - Merge to main and deploy to production

### Quality Standards

- **Configuration Completeness** - All Docker Compose services include comprehensive configuration
- **Health Monitoring** - All services provide health check endpoints
- **Documentation Currency** - Changes include corresponding documentation updates
- **Security Review** - All configurations follow security best practices
- **Environment Parity** - Configurations work consistently across dev/staging/production

## 📄 License

This project is proprietary software developed for Cruise Made Easy operations. All rights reserved.

---

**Cruise Made Easy** - Privacy-focused marketing automation for the modern travel agency.