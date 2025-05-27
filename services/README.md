# CME Stack Services Configuration

This directory contains configuration templates and generated files for all CME stack services.

## 🔐 Security Model

### Template System
- **`.env.template`** files are committed to the repository
- **`.env`** files are generated locally and **never committed**
- All actual secrets and credentials are kept out of version control

### File Types

| File Type | Purpose | Git Status | Contains |
|-----------|---------|------------|----------|
| `.env.template` | Configuration structure | ✅ Committed | Placeholders, no secrets |
| `.env` | Runtime configuration | ❌ Ignored | Real passwords, API keys |
| `config/*.yml` | Service configuration | ✅ Committed | Public config, references env vars |
| `secrets/` | Generated secrets | ❌ Ignored | Certificates, keys |

## 🚀 Getting Started

### 1. Generate Secrets
```bash
# From project root
./scripts/generate-dev-secrets.sh
```

This will:
- Create `.env` files from templates
- Generate secure passwords and keys
- Output database setup commands
- Display admin credentials

### 2. Start Services
```bash
# Core services only
./scripts/compose-dev.sh dev

# All services
./scripts/compose-dev.sh start core
./scripts/compose-dev.sh start infrastructure
./scripts/compose-dev.sh start monitoring
```

## 📁 Service Directory Structure

```
services/
├── wordpress/          # Content management & lead capture
├── matomo/            # Privacy-focused analytics
├── n8n/               # Workflow automation
├── glitchtip/         # Error tracking
├── gitlab/            # Source control & CI/CD (dev only)
├── prometheus/        # Metrics collection
├── grafana/           # Dashboards & visualization
└── loki/              # Log aggregation
```

## 🔧 Configuration Management

### Adding New Services
1. Create service directory: `services/new-service/`
2. Add `.env.template` with placeholder values
3. Update `generate-dev-secrets.sh` to handle the new service
4. Add service to appropriate Docker Compose file

### Updating Templates
- Modify `.env.template` files to add new configuration options
- Run `./scripts/generate-dev-secrets.sh` to regenerate `.env` files
- Templates should use descriptive placeholders like `GENERATED_PASSWORD_32_CHARS`

### Security Best Practices
- Never commit `.env` files or actual secrets
- Use strong, unique passwords for each service
- Regularly rotate credentials in non-development environments
- Keep backup copies of generated credentials in secure password manager

## 🔍 Troubleshooting

### Missing .env Files
```bash
# Regenerate all secrets
./scripts/generate-dev-secrets.sh
```

### Service Configuration Issues
1. Check `.env` file exists and has correct values
2. Verify database connections and credentials
3. Check Docker Compose logs for specific errors
4. Compare with `.env.template` for missing variables

### Database Connection Problems
1. Ensure MariaDB server is running and accessible
2. Run the SQL commands output by `generate-dev-secrets.sh`
3. Test database connectivity from containers
4. Verify firewall settings allow database connections

---

**Security Note**: This directory contains configuration templates only. All actual credentials are generated locally and never committed to version control.