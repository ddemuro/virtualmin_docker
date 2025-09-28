# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a Docker-based Virtualmin deployment that packages Virtualmin (web hosting control panel) with multiple PHP versions and supporting services. The project creates a containerized environment for web hosting management with LDAP, MySQL/MariaDB, mail services, and extensive PHP version support (5.6 through 8.3).

## Architecture

The system consists of multiple Docker containers:
- **tkvmin**: Main Virtualmin container with Apache, multiple PHP versions, mail services (Postfix/Dovecot), DNS (Bind9), and other hosting tools
- **slapd**: OpenLDAP server for directory services
- **slapdweb**: phpLDAPadmin web interface for LDAP management
- **mysql**: MariaDB database server
- **phpmyadmin**: Database management web interface

All containers communicate via a custom bridge network (172.16.235.0/24) and mount volumes from `./virtualmin/` subdirectories for persistent storage.

## Key Commands

### Build and Run
```bash
# Build and start all services
docker-compose up -d

# View logs
docker-compose logs -f [service_name]

# Stop all services
docker-compose down
```

### Service Management
The main container includes service management scripts in `/root/`:
- `start_all_services.sh` - Start all internal services (Apache, PHP-FPM versions, mail services, etc.)
- `start_stop_all_services.sh` - Stop/start all services

Note: The container uses a systemctl replacement (`docker_fixes/systemctl.py`) to handle systemd commands within Docker.

## Environment Configuration

Create a `.env` file from `.env-template` with required passwords and settings:
- `OPERATION`: Container operation mode (default: "startlock")
- `DKIMSELECTOR`: DKIM selector for mail signing
- `VMINMAILNAME`: Mail server hostname
- `SLAPD_PASSWORD`: LDAP admin password
- `MYSQL_ROOT_PASSWORD`: MySQL root password

## Important Implementation Details

1. **SystemD in Docker**: Uses `systemctl.py` replacement script from `docker_fixes/` to handle service management since systemd doesn't run natively in Docker containers.

2. **Missing Entrypoint**: The Dockerfile references `setup/run.sh` as ENTRYPOINT, but this file doesn't exist in the repository. This needs to be created or the container won't start properly.

3. **Volume Mounts**: All configuration and data directories (`/etc`, `/var`, `/home`, `/root`, etc.) are mounted from `./virtualmin/` subdirectories for persistence.

4. **PHP Versions**: Supports PHP 5.6, 7.0-7.4, 8.0-8.3 with extensive module support for each version.

## Port Mappings

- 80, 443: HTTP/HTTPS (Apache)
- 22: SSH
- 25, 587, 465: SMTP (Postfix)
- 110, 995, 143, 993: POP3/IMAP (Dovecot)
- 53: DNS (Bind9)
- 3306: MySQL
- 10000: Virtualmin/Webmin admin panel
- 20000: Usermin
- 10080: phpLDAPadmin
- 10081: phpMyAdmin
