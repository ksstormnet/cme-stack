# CME Stack - Cruise Made Easy

> Privacy-focused, self-hosted marketing automation stack with modular Docker architecture

[![Docker](https://img.shields.io/badge/Docker-20.10+-blue)](https://www.docker.com/)
[![Status](https://img.shields.io/badge/Status-Development-yellow)](https://github.com/yourusername/cme-stack)

## 🚢 Overview

Cruise Made Easy (CME) is a comprehensive, privacy-focused marketing automation stack designed for travel agencies. Built with a modular Docker Compose architecture, it provides complete infrastructure for customer journey management from initial engagement through automated nurturing and scheduling.

### Key Features

- **Privacy-First Analytics** - Self-hosted Matomo with complete visitor data ownership
- **Modular Architecture** - Scalable Docker Compose services with clear separation
- **WordPress Integration** - FrankenWP with built-in caching and performance optimization
- **Workflow Automation** - n8n orchestrating multi-system integrations
- **Complete Observability** - Prometheus, Grafana, and Loki monitoring stack
- **Error Tracking** - GlitchTip for comprehensive exception monitoring
- **Development-Focused** - Local GitLab with full CI/CD capabilities

## 🏗️ Architecture

### Core Services

| Service | Purpose | Technology | Network Access |
|---------|---------|------------|----------------|
| **WordPress** | Content management & personalization | FrankenWP (Caddy + WordPress) | External (Zoraxy) |
| **Matomo** | Privacy-focused visitor analytics | Matomo 4.15 | External (Zoraxy) |
| **n8n** | Workflow automation & orchestration | n8n 1.17.1 | External (Zoraxy) |
| **GlitchTip** | Error tracking & monitoring | GlitchTip (Sentry-compatible) | External (Zoraxy) |
| **GitLab** | Local development & CI/CD | GitLab CE | External (Zoraxy) |
| **Grafana** | Dashboards & visualization | Grafana 10.2.3 | External (Zoraxy) |
| **Prometheus** | Metrics collection & alerting | Prometheus 2.48.1 | External (Zoraxy) |

### External Dependencies

- **MariaDB** - Primary data storage (existing external service)
- **Redis** - Caching & session management (existing external service)
- **Zoraxy** - Reverse proxy with SSL termination

### External Integrations

- **GoHighLevel** - Marketing automation & calendar scheduling
- **TravelJoy** - Final customer management & quoting (CSV import)
- **OpenAI API** - LLM inference for conversational features
- **Voip.ms** - Voice & SMS services

## 🚀 Quick Start

See [DEVELOPMENT-SETUP.md](DEVELOPMENT-SETUP.md) for complete setup instructions.

```bash
# 1. Generate secrets
./scripts/generate-dev-secrets.sh

# 2. Setup database
# (Run SQL commands from secrets script output)

# 3. Start development services
./scripts/compose-dev.sh dev

# 4. Access services via Zoraxy proxy
# WordPress: https://dev-wordpress.cme.ksstorm.dev
# Matomo: https://dev-matomo.cme.ksstorm.dev
# n8n: https://dev-n8n.cme.ksstorm.dev
```

## 📁 Project Structure

```
cme-stack/
├── docker-compose.*.yml         # Modular compose configurations
├── services/                    # Service-specific configurations
│   ├── wordpress/              # FrankenWP setup
│   ├── matomo/                 # Analytics configuration
│   ├── n8n/                    # Workflow automation
│   ├── glitchtip/             # Error tracking
│   └── gitlab/                 # CI/CD
├── monitoring/                  # Observability stack
│   ├── prometheus/             # Metrics collection
│   ├── grafana/               # Dashboards
│   ├── loki/                  # Log aggregation
│   └── alertmanager/          # Alert routing
├── scripts/                    # Management and deployment
└── docs/                      # Technical documentation
```

## 🔧 Development Workflow

### Service Management

```bash
# Start service groups
./scripts/compose-dev.sh start frontend      # WordPress, Matomo, n8n
./scripts/compose-dev.sh start infrastructure # GlitchTip, GitLab
./scripts/compose-dev.sh start monitoring    # Full observability

# Development modes
./scripts/compose-dev.sh dev                 # Core services only
./scripts/compose-dev.sh prod-like           # Full production-like stack

# Monitoring and debugging
./scripts/compose-dev.sh logs [service]      # View logs
./scripts/compose-dev.sh health              # Check service health
```

### Git Branching Strategy

- **main** - Production-ready code
- **staging** - Pre-production testing
- **dev** - Active development integration
- **feature/*** - Feature development branches
- **chore/*** - Infrastructure and maintenance

## 📊 Monitoring & Observability

- **Business Metrics** - Visitor conversion, booking rates, revenue attribution
- **System Metrics** - Container resources, database performance, response times
- **Error Tracking** - Application exceptions, API failures, workflow errors
- **Log Aggregation** - Centralized logging with structured search

Access monitoring:
- **Grafana**: https://dev-grafana.cme.ksstorm.dev
- **Prometheus**: https://dev-prometheus.cme.ksstorm.dev
- **GlitchTip**: https://dev-glitchtip.cme.ksstorm.dev

## 🔐 Security & Privacy

- **GDPR/CCPA Compliant** - Complete visitor data ownership
- **Self-Hosted Analytics** - No third-party data sharing
- **Network Isolation** - Service-to-service communication controls
- **Secrets Management** - Environment-based configuration
- **SSL Termination** - Zoraxy handles all external SSL

## 📚 Documentation

- [Development Setup](DEVELOPMENT-SETUP.md) - Complete environment setup
- [Architecture Overview](docs/ARCHITECTURE.md) - Technical architecture details
- [Deployment Guide](docs/DEPLOYMENT.md) - Production deployment procedures

## 🤝 Contributing

1. Create feature branch from `dev`
2. Develop with live file mounting
3. Test using service health checks
4. Submit PR to `dev` branch
5. Deploy via `staging` → `main` workflow

## 📄 License

This project is proprietary software. All rights reserved.

---

**Cruise Made Easy** - Privacy-focused marketing automation for the modern travel agency.
