-- Production Environment
cme_stack_wordpress   # Live customer content
cme_stack# CME Stack Technical Architecture

> Detailed technical architecture, service interactions, and design decisions for the Cruise Made Easy marketing automation stack

## Architectural Principles

### Privacy-First Design

The CME stack was architected with **complete data ownership** as the primary design principle. Every service that handles visitor or customer data is self-hosted, ensuring:

- **No Third-Party Data Sharing** - Analytics, error tracking, and customer data never leave our infrastructure
- **GDPR/CCPA Compliance** - Full control over data retention, deletion, and access policies
- **Data Residency Control** - Choose exactly where customer data is stored and processed

### Modular Service Architecture

The stack uses **five distinct Docker Compose configurations** to enable flexible deployment scenarios:

- **Core Services** (`docker-compose.core.yml`) - Essential business functionality
- **Infrastructure Services** (`docker-compose.infrastructure.yml`) - Development and operations tools
- **Monitoring Stack** (`docker-compose.monitoring.yml`) - Observability and alerting
- **Development Overrides** (`docker-compose.dev.yml`) - Local development configurations
- **Staging Configuration** (`docker-compose.staging.yml`) - Production-like testing environment

**Why This Approach?**
- **Resource Optimization** - Run only necessary services in each environment
- **Deployment Flexibility** - Scale services independently based on load and requirements
- **Development Efficiency** - Minimal resource usage for focused development work
- **Production Readiness** - Full monitoring stack available when needed

## Service Architecture

### Frontend Services Layer

These services handle direct user interactions and external-facing functionality:

#### WordPress (FrankenWP)
**Technology**: Custom WordPress + Caddy web server
**Purpose**: Content management, lead capture, and personalized customer experience

```yaml
Key Configuration Decisions:
- Caddy web server for automatic HTTPS and performance
- Custom theme development with live file mounting
- Redis integration for object caching and session management
- Database connection to external MariaDB for data persistence
- Integration with Matomo for visitor analytics
```

**Network Position**: `cme-frontend` network, accessible via reverse proxy
**Data Flow**: WordPress ↔ MariaDB (customer data) ↔ Redis (caching) ↔ Matomo (analytics)

#### Matomo Analytics
**Technology**: Matomo 4.15 with PHP-FPM and nginx
**Purpose**: Privacy-focused visitor analytics and conversion tracking

```yaml
Architecture Decisions:
- Self-hosted to maintain complete visitor data ownership
- Dedicated database for analytics data separation
- Custom reporting for cruise industry metrics
- Integration with WordPress for seamless tracking
- No external analytics services (Google Analytics replacement)
```

**Network Position**: `cme-frontend` network, accessible via reverse proxy
**Data Flow**: Website Visitors → Matomo → MariaDB (analytics data)

#### n8n Workflow Automation
**Technology**: n8n 1.17.1 with webhook and API integrations
**Purpose**: Business process automation and external system integration

```yaml
Integration Architecture:
- GoHighLevel CRM synchronization
- OpenAI API for conversational features
- TravelJoy data import/export (CSV processing)
- Voip.ms for SMS and voice communication
- Internal service orchestration (WordPress ↔ Matomo ↔ GlitchTip)
```

**Network Position**: `cme-frontend` and `cme-backend` networks for internal/external communication
**Data Flow**: External APIs ↔ n8n ↔ Internal Services ↔ Database

### Infrastructure Services Layer

These services support development, deployment, and operations:

#### GitLab CE (Development Only)
**Technology**: GitLab Community Edition
**Purpose**: CI/CD pipeline development and staging deployment management

```yaml
Development Workflow Support:
- CI/CD pipeline development and testing in local environment
- Staging deployment automation (GitLab deploys to staging server)
- Container registry for staging builds and testing
- Development issue tracking and project management
- Integration with development monitoring stack
- NOT used for production (GitHub Actions handles production CI/CD)
```

**Network Position**: `dev` environment only, accessible via reverse proxy in development
**Data Flow**: Developer Commits → Local GitLab → GitLab CI/CD → Staging Server Deployment

#### GlitchTip Error Tracking
**Technology**: Sentry-compatible error tracking
**Purpose**: Application error monitoring and performance tracking

```yaml
Error Tracking Strategy:
- WordPress PHP error and performance monitoring
- n8n workflow failure tracking and debugging
- JavaScript error tracking from frontend
- Integration with Grafana for error rate dashboards
- Alert integration for critical error thresholds
```

**Network Position**: `cme-backend` network, accessible via reverse proxy
**Data Flow**: All Services → GlitchTip → Database → Grafana Alerts

### Monitoring and Observability Layer

#### Prometheus Metrics Collection
**Technology**: Prometheus 2.48.1 with custom exporters
**Purpose**: Time-series metrics collection and alerting

```yaml
Metrics Architecture:
- Container and system metrics via cAdvisor
- Application metrics from WordPress, n8n, and custom exporters
- Business metrics (conversion rates, booking pipeline)
- Custom alerting rules for business and technical thresholds
- Integration with Grafana for visualization
```

**Network Position**: `cme-monitoring` network, internal access only
**Data Flow**: All Services → Prometheus → Grafana + AlertManager

#### Grafana Dashboards
**Technology**: Grafana 10.2.3 with custom dashboards
**Purpose**: Metrics visualization and operational dashboards

```yaml
Dashboard Strategy:
- Business performance dashboards (bookings, revenue, conversion)
- Technical performance dashboards (response times, error rates)
- Infrastructure monitoring (resource usage, service health)
- Custom dashboards for cruise industry KPIs
- Integration with Loki for log correlation
```

**Network Position**: `cme-monitoring` network, accessible via reverse proxy
**Data Flow**: Prometheus + Loki → Grafana → Dashboard Views

#### Loki Log Aggregation
**Technology**: Grafana Loki for structured logging
**Purpose**: Centralized log collection and analysis

```yaml
Logging Architecture:
- Structured JSON logging from all services
- Docker container log collection
- Custom log parsing and labeling
- Integration with Grafana for log analysis
- Long-term log retention for compliance
```

**Network Position**: `cme-monitoring` network, internal access only
**Data Flow**: All Service Logs → Loki → Grafana Explore

## Network Architecture

### Docker Network Topology

The CME stack uses **environment-specific network isolation** for security and proper service communication:

```yaml
external:
  Purpose: Reverse proxy communication (shared across environments)
  Services: WordPress, Matomo, n8n, GitLab, Grafana, GlitchTip
  Access: Services that need external access via reverse proxy
  Security: Reverse proxy controls all external access and SSL termination
  Management: Created and managed by reverse proxy system

cme-dev / cme-staging / cme-stack:
  Purpose: Internal service communication (environment-specific)
  Services: All CME services for internal communication
  Access: Service-to-service communication only
  Security: Complete isolation between environments
  Management: Created by Docker Compose for each environment
```

**Network Architecture Benefits**:
- **Environment Isolation** - Dev, staging, and production services cannot communicate
- **Security Boundaries** - Only necessary services exposed to reverse proxy
- **Clear Access Control** - External access only through designated proxy network
- **Operational Simplicity** - Single external network shared across all projects

### External Dependencies

#### MariaDB Database Server
**Architecture Decision**: External database server with environment-specific databases
**Database Schema**:
```sql
-- Development Environment
cme_dev_wordpress     # WordPress content and users
cme_dev_matomo        # Analytics data
cme_dev_n8n           # Workflow definitions and execution history
cme_dev_glitchtip     # Error tracking and performance data
cme_dev_gitlab        # Source control and CI/CD data

-- Staging Environment  
cme_staging_wordpress # Production-like content testing
cme_staging_matomo    # Analytics validation
cme_staging_n8n       # Workflow integration testing
cme_staging_glitchtip # Error tracking validation
-- Note: No GitLab database in staging (GitLab CI/CD deploys from dev environment)

-- Production Environment
cme_stack_wordpress   # Live customer content
cme_stack_matomo      # Live analytics data
cme_stack_n8n         # Production workflows
cme_stack_glitchtip   # Production error tracking
-- Note: No GitLab database in production (GitHub Actions handles CI/CD)
```

**Reasoning**: 
- **Environment Isolation** - Complete data separation between development phases
- **Data Safety** - Development work cannot corrupt staging or production data
- **Testing Fidelity** - Staging can use production-like data volumes
- **Backup Strategy** - Environment-specific backup and restore procedures

#### Redis Cache Server
**Architecture Decision**: External Redis server for caching and sessions
**Reasoning**:
- **Session Persistence** - User sessions survive application container restarts
- **Performance** - Dedicated caching server with memory optimization
- **Shared Cache** - Multiple services (WordPress, n8n) share cache instance
- **High Availability** - Redis clustering available independently

#### Reverse Proxy (External)
**Architecture Decision**: External reverse proxy (Zoraxy) rather than containerized nginx
**Reasoning**:
- **SSL Termination** - Centralized certificate management across multiple projects
- **Load Balancing** - Traffic distribution across multiple CME stack instances
- **Security** - Single point of external access control and DDoS protection
- **Operational Simplicity** - Proxy configuration independent of application deployments

## Environment Configurations

### Development Environment
**Purpose**: Local development with live file mounting and debugging enabled
**Network**: `external` + `cme-dev`
**Databases**: `cme_dev_*` schema prefix

```yaml
Service Modifications:
- Volume mounts for live code editing (WordPress themes, n8n workflows)
- Debug configurations and verbose logging enabled
- Reduced resource limits optimized for laptop development
- Hot reloading for rapid development iteration
- Direct database access tools and debugging interfaces
- Relaxed security configurations for development convenience
```

**Trade-offs**:
- **Performance** - Volume mounts add I/O overhead but enable live editing
- **Security** - Reduced security for development convenience and debugging access
- **Resource Usage** - Optimized for single-developer laptop constraints
- **Data Safety** - Isolated development databases prevent production data corruption

### Staging Environment
**Purpose**: Production-like testing environment for pre-deployment validation
**Network**: `external` + `cme-staging`  
**Databases**: `cme_staging_*` schema prefix

```yaml
Service Modifications:
- Production-like resource limits and performance configurations
- Full monitoring stack enabled with production-like alerting
- Security configurations active (SSL, access controls, secrets management)
- External service integrations active (GoHighLevel, OpenAI, Voip.ms)
- Performance and load testing capabilities enabled
- Production-like data volumes for realistic testing
```

**Trade-offs**:
- **Resource Usage** - Higher resource requirements for full production-like stack
- **Complexity** - More services to manage, monitor, and coordinate
- **Testing Fidelity** - Closest possible match to production for accurate validation
- **Data Management** - Staging data can be refreshed from production snapshots

### Production Environment (Planned)
**Purpose**: Live customer-facing deployment with high availability and performance
**Network**: `external` + `cme-stack`
**Databases**: `cme_prod_*` schema prefix (potentially dedicated MariaDB instance)