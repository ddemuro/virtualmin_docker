# Virtualmin Docker - Full Service Container

A comprehensive Docker-based Virtualmin deployment with full monitoring, multiple PHP versions, and enterprise features.

## Features

- 🚀 **Full Virtualmin/Webmin** control panel
- 🐘 **Multiple PHP versions** (5.6, 7.0-7.4, 8.0-8.3)
- 📊 **Complete monitoring stack** (Grafana, Prometheus, Loki)
- 📧 **Mail services** (Postfix, Dovecot, DKIM)
- 🔒 **Security features** (Fail2ban, ClamAV, SSL/TLS)
- 🗄️ **Database support** (MariaDB with phpMyAdmin)
- 🌐 **DNS management** (BIND9)
- 📁 **LDAP integration** (OpenLDAP with phpLDAPadmin)
- 🔄 **Backup/Restore** capabilities
- 🔧 **Easy management** via sandbox.sh script

## Quick Start

### 1. Clone the Repository

```bash
git clone https://github.com/yourusername/virtualmin_docker.git
cd virtualmin_docker
```

### 2. Configure Environment

```bash
cp .env-template .env
# Edit .env with your passwords and settings
nano .env
```

### 3. Install and Start

```bash
# Make sandbox executable
chmod +x sandbox.sh

# Validate configuration
./sandbox.sh validate

# Install and start all services
./sandbox.sh install
```

### 4. Access Services

| Service | URL | Default Credentials |
|---------|-----|-------------------|
| Virtualmin | https://localhost:10000 | Set during installation |
| Grafana | http://localhost:3000 | admin / (from .env) |
| phpMyAdmin | http://localhost:10081 | root / (from .env) |
| phpLDAPadmin | http://localhost:10080 | admin / (from .env) |

## Sandbox Commands

The `sandbox.sh` script provides comprehensive management:

```bash
./sandbox.sh build       # Build Docker image
./sandbox.sh test        # Run test suite
./sandbox.sh install     # Complete installation
./sandbox.sh status      # Check status
./sandbox.sh logs        # View logs
./sandbox.sh shell       # Open container shell
./sandbox.sh backup      # Create backup
./sandbox.sh restore     # Restore from backup
./sandbox.sh update      # Update OS and Virtualmin
./sandbox.sh monitor     # Show monitoring URLs
./sandbox.sh publish     # Publish to registry
./sandbox.sh clean       # Cleanup containers
```

## Architecture

### Container Stack

- **tkvmin** - Main Virtualmin container with all services
- **mysql** - MariaDB database server
- **slapd** - OpenLDAP directory server
- **prometheus** - Metrics collection
- **grafana** - Monitoring dashboards
- **loki** - Log aggregation
- **node-exporter** - System metrics
- **cadvisor** - Container metrics

### PHP Versions

All PHP versions from 5.6 to 8.3 are installed with extensive module support:
- PHP-FPM for each version
- Apache mod_php support
- CLI tools
- Common extensions (mysql, redis, memcached, etc.)

### Monitoring

Complete observability stack:
- **Metrics**: CPU, Memory, Disk, Network
- **Logs**: Centralized logging with Loki
- **Alerts**: Pre-configured alert rules
- **Dashboards**: Grafana visualizations

## Directory Structure

```
virtualmin_docker/
├── Dockerfile              # Clean, modular Dockerfile
├── docker-compose.yml      # Service orchestration
├── sandbox.sh             # Management script
├── setup/                 # Installation scripts
│   ├── install-packages.sh
│   ├── install-php.sh
│   ├── configure-system.sh
│   ├── run.sh
│   ├── update-os.sh
│   ├── update-virtualmin.sh
│   ├── backup-container.sh
│   └── restore-container.sh
├── monitoring/            # Monitoring configs
│   ├── prometheus/
│   ├── grafana/
│   ├── loki/
│   └── promtail/
└── virtualmin/           # Persistent data volumes
    ├── etc/
    ├── home/
    ├── var/
    └── ...
```

## Configuration

### Environment Variables

Key variables in `.env`:
- `MYSQL_ROOT_PASSWORD` - MySQL root password
- `GRAFANA_PASSWORD` - Grafana admin password
- `LDAP_ADMIN_PASSWORD` - LDAP admin password
- `TZ` - Timezone setting

### Ports

| Port | Service |
|------|---------|
| 22 | SSH |
| 25, 587, 465 | SMTP |
| 53 | DNS |
| 80, 443 | HTTP/HTTPS |
| 110, 995 | POP3/POP3S |
| 143, 993 | IMAP/IMAPS |
| 3000 | Grafana |
| 3306 | MySQL |
| 9090 | Prometheus |
| 10000 | Virtualmin |
| 10080 | phpLDAPadmin |
| 10081 | phpMyAdmin |

## Backup & Restore

### Create Backup

```bash
# Configuration backup
./sandbox.sh backup

# Full backup with data
./sandbox.sh backup --full
```

### Restore Backup

```bash
./sandbox.sh restore --file=./backups/virtualmin-backup-20240101.tar.gz
```

## Updates

### Update OS Packages

```bash
./sandbox.sh update
# Or inside container:
update-os
```

### Update Virtualmin

```bash
update-virtualmin
```

## Publishing to Registry

### Configure Registry

Edit `sandbox.sh` to set your registry:
```bash
REGISTRY="dkr.takelan.com"
NAMESPACE="takelan"
IMAGE_NAME="dockermin"
```

### Publish Image

```bash
# Login to registry
docker login dkr.takelan.com

# Publish with version
./sandbox.sh publish

# Publish with custom tag
./sandbox.sh publish --tag=production
```

## Development

### Build Image

```bash
./sandbox.sh build --no-cache
```

### Run Tests

```bash
./sandbox.sh test --verbose
```

### Debug Container

```bash
./sandbox.sh debug
./sandbox.sh debug --service=apache2
```

## Security

- Fail2ban for intrusion prevention
- ClamAV for virus scanning
- SSL/TLS support with Let's Encrypt
- Firewall rules via iptables
- Regular security updates

## Troubleshooting

### Check Service Status

```bash
./sandbox.sh status
docker exec tkvmin check-services
```

### View Logs

```bash
./sandbox.sh logs --tail=100
docker logs tkvmin
```

### Access Monitoring

```bash
./sandbox.sh monitor
# Visit http://localhost:3000 for Grafana
```

### Common Issues

1. **Services not starting**: Check logs with `./sandbox.sh logs`
2. **Port conflicts**: Ensure ports are not in use
3. **Permission issues**: Run with proper user permissions
4. **Memory issues**: Increase Docker memory allocation

## Requirements

- Docker Engine 20.10+
- Docker Compose 1.29+
- 4GB+ RAM recommended
- 20GB+ disk space

## License

[Your License Here]

## Support

For issues or questions:
1. Check the [SANDBOX.md](SANDBOX.md) documentation
2. Run `./sandbox.sh validate` for configuration check
3. Open an issue on GitHub

## Contributing

Contributions are welcome! Please read the contributing guidelines before submitting PRs.

---

Built with ❤️ for easy Virtualmin deployment