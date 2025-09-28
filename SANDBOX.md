# Virtualmin Docker Sandbox

Complete management tool for building, testing, debugging, and publishing the Virtualmin Docker image.

## Quick Start

```bash
# Make sandbox executable
chmod +x sandbox.sh

# First time setup
./sandbox.sh validate    # Validate configuration
./sandbox.sh install     # Build and install container

# Publish to registry
./sandbox.sh publish
```

## Available Commands

### Build & Deploy

| Command | Description | Example |
|---------|-------------|---------|
| `build` | Build the Docker image | `./sandbox.sh build --no-cache` |
| `install` | Complete installation | `./sandbox.sh install` |
| `publish` | Push to registry | `./sandbox.sh publish --tag=v1.2.3` |

### Testing & Debugging

| Command | Description | Example |
|---------|-------------|---------|
| `test` | Run test suite | `./sandbox.sh test --verbose` |
| `debug` | Debug container | `./sandbox.sh debug --service=apache2` |
| `validate` | Validate configs | `./sandbox.sh validate` |
| `shell` | Open container shell | `./sandbox.sh shell` |

### Management

| Command | Description | Example |
|---------|-------------|---------|
| `status` | Show container status | `./sandbox.sh status` |
| `logs` | View container logs | `./sandbox.sh logs --tail=50` |
| `clean` | Clean up containers | `./sandbox.sh clean --force` |
| `update` | Update OS & Virtualmin | `./sandbox.sh update` |

### Backup & Restore

| Command | Description | Example |
|---------|-------------|---------|
| `backup` | Create backup | `./sandbox.sh backup --full` |
| `restore` | Restore from backup | `./sandbox.sh restore --file=backup.tar.gz` |

### Version Management

| Command | Description | Example |
|---------|-------------|---------|
| `version show` | Display current version | `./sandbox.sh version show` |
| `version bump` | Increment version | `./sandbox.sh version bump` |
| `version set` | Set specific version | `./sandbox.sh version set 2.0.0` |

## Publishing to Private Registry

The sandbox is configured to publish to your private registry at `dkr.takelan.com`.

### Initial Setup

1. Login to your registry:
```bash
docker login dkr.takelan.com
```

2. Build and tag the image:
```bash
./sandbox.sh build
```

3. Publish with automatic versioning:
```bash
./sandbox.sh publish
```

4. Or publish with custom tag:
```bash
./sandbox.sh publish --tag=production
./sandbox.sh publish --tag=v2.0.0
```

### Published Image Details

- **Registry**: `dkr.takelan.com`
- **Namespace**: `takelan`
- **Repository**: `dockermin`
- **Full path**: `dkr.takelan.com/takelan/dockermin`
- **Tags**: Version numbers and `latest`

### Pulling Published Image

```bash
# Pull latest version
docker pull dkr.takelan.com/takelan/dockermin:latest

# Pull specific version
docker pull dkr.takelan.com/takelan/dockermin:1.0.0

# Use in docker-compose.yml
services:
  virtualmin:
    image: dkr.takelan.com/takelan/dockermin:latest
```

## Testing Suite

The sandbox includes comprehensive testing:

### Service Tests
- Apache2 web server
- MySQL/MariaDB database
- Postfix mail server
- Dovecot IMAP/POP3
- BIND9 DNS server
- SSH server

### PHP Version Tests
- PHP 5.6, 7.0, 7.1, 7.2, 7.3, 7.4
- PHP 8.0, 8.1, 8.2, 8.3

### Web Service Tests
- Apache HTTP/HTTPS
- Webmin/Virtualmin panel
- Health check endpoints

Run complete test suite:
```bash
./sandbox.sh test --verbose
```

## Debug Mode

Enter debug mode to troubleshoot issues:

```bash
# General debug
./sandbox.sh debug

# Debug specific service
./sandbox.sh debug --service=apache2
./sandbox.sh debug --service=mysql
./sandbox.sh debug --service=postfix
```

Debug mode provides:
- Container information
- Running processes
- Service status
- Recent logs
- Interactive shell

## Container Management

### View Status
```bash
./sandbox.sh status
```

### Monitor Logs
```bash
# Last 100 lines
./sandbox.sh logs

# Follow logs
./sandbox.sh logs --follow

# Custom tail
./sandbox.sh logs --tail=200
```

### Access Shell
```bash
./sandbox.sh shell
```

## Backup & Recovery

### Create Backups
```bash
# Configuration backup
./sandbox.sh backup

# Full backup (includes data)
./sandbox.sh backup --full
```

Backups are saved to `./backups/` directory.

### Restore from Backup
```bash
# List available backups
ls -lh ./backups/

# Restore specific backup
./sandbox.sh restore --file=./backups/virtualmin-backup-20240101-120000.tar.gz
```

## Updates

Keep container updated:

```bash
# Update OS packages and Virtualmin
./sandbox.sh update
```

This runs:
- OS package updates
- Virtualmin updates
- Security patches
- Virus definition updates

## Configuration Validation

Before deployment, validate all configurations:

```bash
./sandbox.sh validate
```

Checks:
- Dockerfile syntax
- docker-compose.yml validity
- Environment variables
- Script syntax
- File permissions

## Environment Configuration

Copy and configure environment:

```bash
cp .env-template .env
# Edit .env with your settings
nano .env
```

Required variables:
- `MYSQL_ROOT_PASSWORD`
- `SLAPD_PASSWORD`
- `LDAP_ADMIN_PASSWORD`

## Options

### Global Options

| Option | Description |
|--------|-------------|
| `--force` | Skip confirmations |
| `--verbose` | Detailed output |
| `--no-cache` | Build without cache |

### Command-Specific Options

| Command | Options |
|---------|---------|
| `publish` | `--tag=VERSION` |
| `logs` | `--follow`, `--tail=N` |
| `backup` | `--full` |
| `restore` | `--file=PATH` |
| `debug` | `--service=NAME` |

## Troubleshooting

### Container Won't Start
```bash
./sandbox.sh validate
./sandbox.sh debug
```

### Build Fails
```bash
./sandbox.sh build --no-cache
```

### Service Issues
```bash
./sandbox.sh debug --service=SERVICE_NAME
./sandbox.sh logs --tail=100
```

### Registry Push Fails
```bash
docker login dkr.takelan.com
./sandbox.sh publish --verbose
```

## Version Management

The sandbox automatically manages versions:

1. Version is stored in `.version` file
2. Auto-incremented on successful publish
3. Manual version control available

```bash
# Check version
./sandbox.sh version show

# Bump version (patch)
./sandbox.sh version bump

# Set specific version
./sandbox.sh version set 2.0.0
```

## CI/CD Integration

Use sandbox in CI/CD pipelines:

```yaml
# GitLab CI example
build:
  script:
    - ./sandbox.sh build --no-cache
    - ./sandbox.sh test

deploy:
  script:
    - ./sandbox.sh publish --tag=$CI_COMMIT_TAG
  only:
    - tags
```

## Support

For issues or questions about the sandbox:
1. Run validation: `./sandbox.sh validate`
2. Check debug output: `./sandbox.sh debug`
3. Review logs: `./sandbox.sh logs --tail=200`

## License

This sandbox script is part of the Virtualmin Docker project.