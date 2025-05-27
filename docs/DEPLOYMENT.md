# CME Stack Deployment Guide

> Development → Staging → Production workflow and deployment procedures

## Deployment Strategy Overview

The CME stack follows a **three-environment deployment pipeline** designed to ensure code quality, thorough testing, and safe production releases:

```
Development → Staging → Production
    ↓           ↓          ↓
  cme-dev   cme-staging  cme-stack
```

### Environment Characteristics

| Environment | Purpose | Network | Database Prefix | External Access |
|------------|---------|---------|-----------------|-----------------|
| **Development** | Active development and debugging | `cme-dev` | `cme_dev_*` | `dev-*.cme.ksstorm.dev` |
| **Staging** | Pre-production testing and validation | `cme-staging` | `cme_staging_*` | `staging-*.cme.ksstorm.dev` |
| **Production** | Live customer-facing deployment | `cme-stack` | `cme_stack_*` | `*.cruisemadeeasy.com` |

## Development Workflow

### Git Branching Strategy

```
main (production) ← GitHub Actions deployment
├── staging (pre-production)
│   ├── dev (integration)
│   │   ├── feature/new-booking-flow
│   │   ├── feature/analytics-enhancement
│   │   └── chore/monitoring-improvements
│   └── hotfix/critical-security-update
```

### Branch Responsibilities

- **main** - Production-ready code, automatically deployed to production via GitHub Actions
- **staging** - Staging environment deployment, thoroughly tested code
- **dev** - Development integration, continuous deployment to dev environment
- **feature/*** - Feature development branches, merged to dev
- **chore/*** - Infrastructure and maintenance, merged to dev
- **hotfix/*** - Critical fixes, can be merged directly to staging/main

### Source Control Strategy

- **GitHub (Production)** - Primary repository hosting at GitHub with Actions for production deployment
- **GitLab (Development)** - Local GitLab instance for CI/CD pipeline development and staging deployments
- **Deployment Flow** - GitLab CI/CD deploys to staging server, GitHub Actions deploys to production

## Development Environment

### Purpose and Scope

The development environment is designed for:
- **Active Code Development** - Live file mounting for immediate code changes
- **Feature Testing** - Individual feature validation and debugging
- **Integration Development** - Testing service interactions and API integrations
- **Workflow Development** - n8n automation development and testing

### Deployment Process

```bash
# 1. Start development environment
git checkout dev
./scripts/compose-dev.sh dev

# 2. Develop with live file mounting
# - WordPress themes: services/wordpress/themes/
# - n8n workflows: services/n8n/workflows/
# - Configuration: services/*/config/

# 3. Test changes
./scripts/compose-dev.sh health
./scripts/compose-dev.sh logs [service]

# 4. Commit and push to dev branch
git add .
git commit -m "feat: implement new booking flow"
git push origin feature/new-booking-flow

# 5. Create pull request to dev branch
# Dev environment automatically updates on dev branch changes
```

### Development Database Management

```sql
-- Development databases are isolated and disposable
-- Safe to reset/refresh as needed for testing

-- Reset development data
DROP DATABASE cme_dev_wordpress;
CREATE DATABASE cme_dev_wordpress;

-- Import fresh data for testing
mysql cme_dev_wordpress < test-data/wordpress-sample.sql
```

## Staging Environment

### Purpose and Scope

The staging environment provides:
- **Production Validation** - Production-like configuration and performance testing
- **Integration Testing** - Full external service integration validation
- **User Acceptance Testing** - Customer-like environment for final approval
- **Performance Testing** - Load testing and performance validation
- **Security Testing** - Production security configuration validation

### Deployment Process

```bash
# 1. Promote code from dev to staging
git checkout staging
git merge dev
git push origin staging

# 2. Deploy to staging environment
git checkout staging
./scripts/compose-dev.sh staging

# 3. Run integration tests
./scripts/test-integration.sh staging
./scripts/test-performance.sh staging

# 4. Validate external integrations
# - GoHighLevel API connectivity
# - OpenAI API functionality  
# - Voip.ms SMS/voice services
# - Analytics data collection

# 5. User acceptance testing
# - Customer journey testing
# - Booking flow validation
# - Analytics and reporting verification

# 6. Performance and security validation
# - Load testing under realistic conditions
# - Security scan and penetration testing
# - SSL configuration and certificate validation
```

### Staging Database Management

```sql
-- Staging databases can be refreshed from production snapshots
-- Provides realistic data volumes for testing

-- Refresh staging data from production (planned procedure)
mysqldump cme_stack_wordpress > prod-snapshot.sql
mysql cme_staging_wordpress < prod-snapshot.sql

-- Sanitize sensitive data for staging
UPDATE cme_staging_wordpress.wp_users SET user_email = 'test@example.com';
UPDATE cme_staging_wordpress.wp_users SET user_pass = 'hashed_test_password';
```

### Staging Validation Checklist

- [ ] **Service Health** - All services start and pass health checks
- [ ] **External Integrations** - API connections and data flows working
- [ ] **User Workflows** - Complete customer journey from landing to booking
- [ ] **Analytics Tracking** - Visitor tracking and conversion measurement
- [ ] **Error Handling** - Error tracking and alerting functioning
- [ ] **Performance** - Response times meet production requirements
- [ ] **Security** - SSL, authentication, and access controls active
- [ ] **Monitoring** - Dashboards and alerts functioning correctly

## Production Environment (Planned)

### Purpose and Scope

The production environment will provide:
- **Live Customer Service** - Customer-facing booking and information platform
- **High Availability** - Redundant services and failover capabilities
- **Performance Optimization** - Optimized for customer experience and conversion
- **Security Hardening** - Production-grade security and compliance
- **Business Continuity** - Backup, disaster recovery, and data protection

### Production Deployment Process (Framework)

*Note: This process will be fully developed as we build out production infrastructure*

```bash
# 1. Final staging validation
./scripts/validate-staging.sh --production-readiness

# 2. Production deployment preparation
# - Database migration planning
# - Service configuration validation  
# - Backup and rollback procedures
# - Monitoring and alerting setup

# 3. Blue-green deployment (planned)
# - Deploy to production-blue environment
# - Validate new deployment
# - Switch traffic from production-green to production-blue
# - Monitor for issues and rollback if necessary

# 4. Post-deployment validation
# - Health checks across all services
# - Customer journey validation
# - Performance monitoring
# - Error rate monitoring
```

### Production Database Strategy (Planned)

```sql
-- Production databases will have:
-- - Dedicated MariaDB instance with high availability
-- - Automated backup and point-in-time recovery
-- - Performance optimization for customer workloads
-- - Security hardening and access controls

-- Production database naming
cme_stack_wordpress   -- Customer content and bookings
cme_stack_matomo      -- Customer analytics (GDPR compliant)
cme_stack_n8n         -- Production workflow automation
cme_stack_glitchtip   -- Production error tracking
-- Note: No GitLab database in production (GitHub Actions handles CI/CD)
```

## Rollback Procedures

### Development Rollback

```bash
# Development rollbacks are typically simple
git checkout dev
git reset --hard HEAD~1  # Roll back last commit
./scripts/compose-dev.sh restart
```

### Staging Rollback

```bash
# Staging rollback to previous stable version
git checkout staging
git reset --hard [previous-stable-commit]
./scripts/compose-dev.sh staging
./scripts/validate-staging.sh
```

### Production Rollback (Planned)

*Production rollback procedures will be developed with blue-green deployment strategy*

## Monitoring and Alerting

### Deployment Monitoring

Each environment includes monitoring for:
- **Service Health** - Container status and health check monitoring
- **Application Performance** - Response times and error rates
- **Business Metrics** - Booking conversion and customer journey completion
- **Infrastructure** - Resource usage and capacity planning

### Deployment Alerts

- **Failed Deployments** - Immediate notification of deployment failures
- **Performance Degradation** - Alerts when response times exceed thresholds
- **Error Rate Increases** - Notification of increased error rates post-deployment
- **Service Outages** - Immediate notification of service unavailability

## Security Considerations

### Environment Security

- **Network Isolation** - Each environment uses isolated Docker networks
- **Database Isolation** - Environment-specific database schemas
- **Secrets Management** - Environment-specific secrets and API keys
- **Access Controls** - Environment-appropriate authentication and authorization

### Production Security (Planned)

- **SSL/TLS Termination** - Production-grade certificate management
- **DDoS Protection** - Traffic filtering and rate limiting
- **Intrusion Detection** - Security monitoring and threat detection
- **Compliance** - GDPR/CCPA compliance monitoring and reporting

## Performance Optimization

### Environment-Specific Optimization

- **Development** - Optimized for development speed and debugging
- **Staging** - Production-like performance for accurate testing
- **Production** - Optimized for customer experience and business conversion

### Performance Monitoring

- **Customer Experience Metrics** - Page load times, booking completion rates
- **System Performance** - Container resource usage, database performance
- **Business Impact** - Revenue attribution, conversion optimization

## Backup and Recovery

### Development Backup

- **Code Repository** - Git version control with remote repositories
- **Database** - Development databases are disposable and recreatable
- **Configuration** - All configurations stored in version control

### Staging/Production Backup (Planned)

- **Database Backup** - Automated daily backups with point-in-time recovery
- **File System Backup** - WordPress media files and uploaded content
- **Configuration Backup** - Environment-specific configurations and secrets
- **Disaster Recovery** - Complete environment restoration procedures

## Future Enhancements

As the CME stack evolves, deployment procedures will be enhanced with:

- **Automated Testing** - Comprehensive test suites for each deployment stage
- **Blue-Green Deployment** - Zero-downtime production deployments
- **Infrastructure as Code** - Terraform or similar for infrastructure management
- **Container Orchestration** - Kubernetes or Docker Swarm for production scaling
- **Advanced Monitoring** - Enhanced observability and performance analytics

---

*This deployment guide will be updated as we develop and implement each phase of the deployment pipeline.*