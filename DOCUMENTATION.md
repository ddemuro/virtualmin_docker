# Virtualmin Docker - Complete Documentation

## Table of Contents

- [Architecture Overview](#architecture-overview)
- [Container Services](#container-services)
- [Environment Variables](#environment-variables)
- [Volume Mappings](#volume-mappings)
- [Network Configuration](#network-configuration)
- [Port Mappings](#port-mappings)
- [Backup System](#backup-system)
- [Monitoring Stack](#monitoring-stack)
- [Service Management](#service-management)
- [PHP Versions](#php-versions)
- [Security Considerations](#security-considerations)

## Architecture Overview

This project implements a fully containerized Virtualmin hosting environment with multiple supporting services. The architecture consists of:

- **Main Application Container** (tkvmin): Virtualmin/Webmin control panel with web hosting services
- **Database Container** (mysql): MariaDB for application databases
- **LDAP Container** (slapd): OpenLDAP for directory services
- **Management Interfaces**: phpMyAdmin and phpLDAPadmin
- **Monitoring Stack**: Prometheus, Grafana, Loki for observability
- **Backup System**: Automated backup with rotation and verification

## Container Services

### 1. Main Container (tkvmin)

The primary container running Virtualmin and all web hosting services.

**Services Included:**

- **Apache 2.4**: Web server with mod_rewrite, SSL, headers, expires, deflate, proxy, and proxy_fcgi
- **Multiple PHP Versions**: 5.6, 7.0, 7.1, 7.2, 7.3, 7.4, 8.0, 8.1, 8.2, 8.3 (all with PHP-FPM)
- **Postfix**: SMTP mail server
- **Dovecot**: IMAP/POP3 mail server
- **BIND9**: DNS server
- **ProFTPD**: FTP server
- **SSH Server**: Remote access
- **Fail2ban**: Intrusion prevention
- **ClamAV**: Antivirus scanning
- **SpamAssassin**: Spam filtering
- **Webmin/Virtualmin**: Web-based control panel
- **Usermin**: User control panel

**Configuration:**

```yaml
tkvmin:
  container_name: tkvmin
  hostname: virtualmin.local
  restart: unless-stopped
  privileged: true
```

### 2. MySQL Container

MariaDB database server for application databases.

**Version:** MariaDB 10.11

**Configuration:**

```yaml
mysql:
  container_name: mysql
  image: mariadb:10.11
  restart: unless-stopped
```

**Settings:**

- Root password set via `MYSQL_ROOT_PASSWORD` environment variable
- Character set: UTF-8
- Collation: utf8_general_ci
- Max connections: 500
- InnoDB buffer pool size: Auto-configured

### 3. SLAPD Container

OpenLDAP server for centralized authentication and directory services.

**Configuration:**

```yaml
slapd:
  container_name: slapd
  image: osixia/openldap:latest
  restart: unless-stopped
```

**Settings:**

- Organization: Set via `LDAP_ORGANISATION`
- Domain: Set via `LDAP_DOMAIN`
- Admin password: Set via `LDAP_ADMIN_PASSWORD`
- Config password: Set via `LDAP_CONFIG_PASSWORD`
- Base DN: Automatically derived from domain

### 4. phpLDAPadmin Container

Web-based LDAP administration interface.

**Access:** <https://localhost:10080>

**Configuration:**

```yaml
slapdweb:
  container_name: slapdweb
  image: osixia/phpldapadmin:latest
```

**Login Credentials:**

- Login DN: `cn=admin,dc=example,dc=com` (adjust based on your domain)
- Password: Value of `LDAP_ADMIN_PASSWORD`

### 5. phpMyAdmin Container

Web-based MySQL administration interface.

**Access:** <http://localhost:10081>

**Configuration:**

```yaml
phpmyadmin:
  container_name: phpmyadmin
  image: phpmyadmin:latest
```

**Login Credentials:**

- Username: root
- Password: Value of `MYSQL_ROOT_PASSWORD`

## Environment Variables

Create a `.env` file from `.env-template` with the following variables:

### Required Variables

| Variable | Description | Example | Required |
|----------|-------------|---------|----------|
| `OPERATION` | Container operation mode | `startlock` | Yes |
| `DKIMSELECTOR` | DKIM selector for mail signing | `mail` | Yes |
| `VMINMAILNAME` | Mail server hostname | `mail.example.com` | Yes |
| `SLAPD_PASSWORD` | LDAP admin password | `SecurePassword123!` | Yes |
| `MYSQL_ROOT_PASSWORD` | MySQL root password | `SecureDBPass456!` | Yes |

### Optional Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `LDAP_ORGANISATION` | LDAP organization name | `Example Inc` |
| `LDAP_DOMAIN` | LDAP domain | `example.com` |
| `LDAP_CONFIG_PASSWORD` | LDAP config password | Same as `SLAPD_PASSWORD` |
| `LDAP_READONLY_USER` | Enable readonly user | `false` |
| `LDAP_RFC2307BIS_SCHEMA` | Use RFC2307bis schema | `false` |
| `LDAP_TLS` | Enable TLS | `true` |
| `ALERT_EMAIL` | Email for backup alerts | `admin@example.com` |
| `BACKUP_RETENTION_DAYS` | Daily backup retention | `7` |
| `BACKUP_RETENTION_WEEKLY` | Weekly backup retention (weeks) | `4` |
| `BACKUP_RETENTION_MONTHLY` | Monthly backup retention (months) | `3` |
| `TZ` | Timezone | `UTC` |

## Volume Mappings

### Main Container Volumes

| Host Path | Container Path | Purpose |
|-----------|---------------|---------|
| `./virtualmin/etc` | `/etc` | System configuration |
| `./virtualmin/var` | `/var` | Variable data |
| `./virtualmin/usr` | `/usr` | User programs |
| `./virtualmin/home` | `/home` | User home directories |
| `./virtualmin/root` | `/root` | Root home directory |
| `./virtualmin/opt` | `/opt` | Optional software |
| `./virtualmin/srv` | `/srv` | Service data |
| `./virtualmin/lib` | `/lib` | System libraries |
| `./virtualmin/lib64` | `/lib64` | 64-bit libraries |
| `./backups` | `/backups` | Backup storage |
| `./data` | `/data` | Shared data |

### Database Volumes

| Host Path | Container Path | Purpose |
|-----------|---------------|---------|
| `./mysql/data` | `/var/lib/mysql` | Database files |
| `./mysql/conf` | `/etc/mysql/conf.d` | Custom configuration |
| `./backups/mysql` | `/backups` | Database backups |

### LDAP Volumes

| Host Path | Container Path | Purpose |
|-----------|---------------|---------|
| `./ldap/data` | `/var/lib/ldap` | LDAP database |
| `./ldap/config` | `/etc/ldap/slapd.d` | LDAP configuration |
| `./ldap/certs` | `/container/service/slapd/assets/certs` | SSL certificates |

### Monitoring Volumes

| Host Path | Container Path | Purpose |
|-----------|---------------|---------|
| `./monitoring/prometheus` | `/etc/prometheus` | Prometheus config |
| `./monitoring/grafana` | `/etc/grafana/provisioning` | Grafana dashboards |
| `./monitoring/loki` | `/etc/loki` | Loki configuration |
| `./monitoring/promtail` | `/etc/promtail` | Promtail config |

## Network Configuration

### Custom Bridge Network

**Network Name:** `virtualmin_network`
**Subnet:** `172.16.235.0/24`

### Static IP Assignments

| Container | IP Address | Hostname |
|-----------|------------|----------|
| tkvmin | 172.16.235.10 | virtualmin.local |
| mysql | 172.16.235.20 | mysql.local |
| slapd | 172.16.235.30 | ldap.local |
| slapdweb | 172.16.235.31 | ldapadmin.local |
| phpmyadmin | 172.16.235.40 | phpmyadmin.local |
| prometheus | 172.16.235.50 | prometheus.local |
| grafana | 172.16.235.51 | grafana.local |
| loki | 172.16.235.52 | loki.local |
| promtail | 172.16.235.53 | promtail.local |
| node-exporter | 172.16.235.54 | node-exporter.local |
| cadvisor | 172.16.235.55 | cadvisor.local |

## Port Mappings

### Web Services

| Port | Service | Description |
|------|---------|-------------|
| 80 | HTTP | Apache web server |
| 443 | HTTPS | Apache SSL |
| 10000 | Webmin/Virtualmin | Control panel |
| 20000 | Usermin | User control panel |

### Mail Services

| Port | Service | Description |
|------|---------|-------------|
| 25 | SMTP | Mail delivery |
| 587 | Submission | Mail submission |
| 465 | SMTPS | Secure SMTP |
| 110 | POP3 | Mail retrieval |
| 995 | POP3S | Secure POP3 |
| 143 | IMAP | Mail access |
| 993 | IMAPS | Secure IMAP |

### Database & Directory Services

| Port | Service | Description |
|------|---------|-------------|
| 3306 | MySQL | Database server |
| 389 | LDAP | Directory service |
| 636 | LDAPS | Secure LDAP |
| 10080 | phpLDAPadmin | LDAP web interface |
| 10081 | phpMyAdmin | MySQL web interface |

### Other Services

| Port | Service | Description |
|------|---------|-------------|
| 22 | SSH | Remote shell access |
| 53 | DNS | Domain name service |
| 21 | FTP | File transfer |
| 990 | FTPS | Secure FTP |

### Monitoring Services

| Port | Service | Description |
|------|---------|-------------|
| 9090 | Prometheus | Metrics database |
| 3000 | Grafana | Visualization |
| 3100 | Loki | Log aggregation |
| 9080 | Promtail | Log collector |
| 9100 | Node Exporter | System metrics |
| 8080 | cAdvisor | Container metrics |

## Backup System

### Automated Backup Schedule

| Schedule | Script | Description |
|----------|--------|-------------|
| Daily 2:00 AM | `automated-backup.sh` | Full system backup |
| Every 6 hours | `quick-backup.sh` | Configuration backup |
| Every 4 hours | `mysql-backup.sh` | Database backup |
| Daily 6:00 AM | `verify-backups.sh` | Backup integrity check |
| Weekly Sunday 3:00 AM | `cleanup-backups.sh` | Old backup removal |
| Weekly Monday 8:00 AM | `backup-report.sh` | Generate backup report |

### Backup Locations

| Directory | Content | Retention |
|-----------|---------|-----------|
| `/backups/daily` | Daily full backups | 7 days |
| `/backups/weekly` | Weekly archives | 4 weeks |
| `/backups/monthly` | Monthly archives | 3 months |
| `/backups/quick` | Config snapshots | 2 days |
| `/backups/mysql` | Database backups | 2 days |

### Backup Contents

**System Backup Includes:**

- Virtualmin configuration (`/etc/webmin`)
- Apache configuration (`/etc/apache2`)
- PHP configurations (all versions)
- Mail server configs (Postfix/Dovecot)
- DNS zones (`/etc/bind`)
- SSL certificates (`/etc/ssl`)
- Website data (`/home/*/public_html`)
- Mail directories (`/home/*/Maildir`)
- User accounts and permissions

**Database Backup:**

- All MySQL databases
- User privileges
- Stored procedures and functions
- Triggers and events

**LDAP Backup:**

- Complete directory tree
- Schema definitions
- Access control lists

## Monitoring Stack

### Prometheus Configuration

**Scrape Targets:**

- Virtualmin container metrics
- MySQL exporter metrics
- Node exporter (system metrics)
- cAdvisor (container metrics)

**Alert Rules:**

- High CPU usage (>80%)
- High memory usage (>90%)
- Disk space low (<10% free)
- Service down alerts
- Backup failure alerts

### Grafana Dashboards

**Pre-configured Dashboards:**

- System Overview
- Container Performance
- MySQL Performance
- Web Server Metrics
- Mail Server Statistics
- Backup Status

**Default Credentials:**

- Username: `admin`
- Password: `admin` (change on first login)

### Loki Log Aggregation

**Log Sources:**

- Apache access and error logs
- PHP error logs
- Mail server logs
- MySQL query logs
- System logs
- Backup logs

**Log Retention:** 30 days

## Service Management

### Starting Services

```bash
# Start all containers
docker-compose up -d

# Start specific service
docker-compose up -d tkvmin

# Start with build
docker-compose up -d --build
```

### Stopping Services

```bash
# Stop all containers
docker-compose down

# Stop and remove volumes
docker-compose down -v

# Stop specific service
docker-compose stop tkvmin
```

### Service Commands Inside Container

```bash
# Check all services
/usr/local/bin/check-services

# Restart all services
/usr/local/bin/restart-all

# Update OS packages
/usr/local/bin/update-os

# Update Virtualmin
/usr/local/bin/update-virtualmin

# Manual backup
/usr/local/bin/automated-backup.sh

# Quick backup
/usr/local/bin/quick-backup.sh
```

## PHP Versions

### Available PHP Versions

| Version | Status | PHP-FPM Socket |
|---------|--------|----------------|
| PHP 5.6 | Legacy | `/var/run/php/php5.6-fpm.sock` |
| PHP 7.0 | EOL | `/var/run/php/php7.0-fpm.sock` |
| PHP 7.1 | EOL | `/var/run/php/php7.1-fpm.sock` |
| PHP 7.2 | EOL | `/var/run/php/php7.2-fpm.sock` |
| PHP 7.3 | EOL | `/var/run/php/php7.3-fpm.sock` |
| PHP 7.4 | Security | `/var/run/php/php7.4-fpm.sock` |
| PHP 8.0 | Active | `/var/run/php/php8.0-fpm.sock` |
| PHP 8.1 | Active | `/var/run/php/php8.1-fpm.sock` |
| PHP 8.2 | Active | `/var/run/php/php8.2-fpm.sock` |
| PHP 8.3 | Current | `/var/run/php/php8.3-fpm.sock` |

### PHP Extensions Installed

**Common Extensions (All Versions):**

- bcmath, bz2, calendar, ctype, curl
- dba, dom, enchant, exif, fileinfo
- ftp, gd, gettext, gmp, iconv
- imap, intl, json, ldap, mbstring
- mysqli, opcache, pdo, pgsql, phar
- posix, readline, session, soap, sockets
- sqlite3, tokenizer, xml, xmlrpc, zip

**Version-Specific Extensions:**

- PHP 5.6: mcrypt, mysql, mssql
- PHP 7.x: mcrypt (7.0-7.1 only)
- PHP 8.x: JIT compiler support

### Switching PHP Versions

In Virtualmin:

1. Select virtual server
2. Go to "Server Configuration" → "PHP Options"
3. Select PHP version from dropdown
4. Apply changes

Via Command Line:

```bash
# For a specific domain
virtualmin modify-web --domain example.com --php-version 8.2
```

## Security Considerations

### Container Security

**Privileged Mode:** The main container runs in privileged mode to allow:

- Multiple service management
- Filesystem operations
- Network configuration
- Process management

**Security Measures:**

- Fail2ban for intrusion prevention
- ClamAV for virus scanning
- SpamAssassin for mail filtering
- SSL/TLS encryption enabled
- Firewall rules via iptables
- SELinux contexts preserved

### Password Security

**Password Requirements:**

- Minimum 12 characters recommended
- Use mix of uppercase, lowercase, numbers, symbols
- Different passwords for each service
- Store passwords in `.env` file (not in repository)
- Rotate passwords regularly

### Network Security

**Isolation:**

- Custom bridge network isolates containers
- No direct internet exposure for database/LDAP
- Services communicate via internal network

**Recommendations:**

- Use reverse proxy for public access
- Implement rate limiting
- Enable mod_security for Apache
- Use strong SSL certificates
- Regular security updates

### Backup Security

**Backup Protection:**

- Encrypted backup options available
- Offsite backup recommended
- Regular backup verification
- Retention policies enforced
- Access logs maintained

### Monitoring Security

**Access Control:**

- Change default Grafana password
- Limit Prometheus access
- Secure monitoring endpoints
- Use HTTPS for web interfaces
- Regular audit log reviews

## Troubleshooting

### Common Issues

**Container Won't Start:**

- Check `.env` file exists and has all required variables
- Verify Docker daemon is running
- Check port conflicts with `netstat -tulpn`
- Review logs: `docker-compose logs tkvmin`

**Services Not Running:**

- Check supervisor: `docker exec tkvmin supervisorctl status`
- Restart services: `docker exec tkvmin /usr/local/bin/restart-all`
- Check individual service logs in `/var/log/`

**Backup Failures:**

- Verify disk space: `df -h /backups`
- Check backup log: `/backups/backup.log`
- Run verification: `/usr/local/bin/verify-backups.sh`
- Check cron: `docker exec tkvmin crontab -l`

**Database Connection Issues:**

- Verify MySQL is running: `docker-compose ps mysql`
- Check network connectivity: `docker exec tkvmin ping mysql`
- Verify credentials in `.env` file
- Check MySQL logs: `docker-compose logs mysql`

**Mail Not Working:**

- Check Postfix: `docker exec tkvmin postfix status`
- Review mail log: `/var/log/mail.log`
- Verify DNS records (MX, SPF, DKIM)
- Check port 25 connectivity

### Log Locations

| Service | Log Path |
|---------|----------|
| Apache | `/var/log/apache2/error.log` |
| PHP | `/var/log/php*.log` |
| MySQL | `/var/log/mysql/error.log` |
| Mail | `/var/log/mail.log` |
| Virtualmin | `/var/log/virtualmin/` |
| Backup | `/backups/backup.log` |
| System | `/var/log/syslog` |

### Performance Tuning

**Apache Optimization:**

```apache
# Adjust in /etc/apache2/mods-enabled/mpm_event.conf
MaxRequestWorkers 150
ServerLimit 150
ThreadsPerChild 25
```

**PHP-FPM Tuning:**

```ini
# Adjust in /etc/php/*/fpm/pool.d/www.conf
pm = dynamic
pm.max_children = 50
pm.start_servers = 5
pm.min_spare_servers = 5
pm.max_spare_servers = 35
```

**MySQL Tuning:**

```ini
# Adjust in /etc/mysql/conf.d/custom.cnf
innodb_buffer_pool_size = 1G
max_connections = 200
query_cache_size = 128M
```

## Maintenance

### Regular Maintenance Tasks

**Daily:**

- Monitor backup logs
- Check service status
- Review error logs

**Weekly:**

- Verify backup integrity
- Review security logs
- Check disk usage

**Monthly:**

- Update system packages
- Review user accounts
- Performance analysis
- Security audit

### Update Procedures

**OS Updates:**

```bash
docker exec tkvmin /usr/local/bin/update-os
```

**Virtualmin Updates:**

```bash
docker exec tkvmin /usr/local/bin/update-virtualmin
```

**Container Updates:**

```bash
# Update base images
docker-compose pull

# Rebuild and restart
docker-compose up -d --build
```

### Disaster Recovery

**Backup Recovery:**

```bash
# Full restore
docker exec tkvmin /usr/local/bin/restore-container full /backups/daily/backup-20240101.tar.gz

# Selective restore
docker exec tkvmin /usr/local/bin/restore-container mysql /backups/mysql/mysql-20240101.sql.gz
```

**Container Recovery:**

```bash
# Rebuild from scratch
docker-compose down -v
docker-compose up -d --build

# Restore data
docker exec tkvmin /usr/local/bin/restore-container full /backups/latest.tar.gz
```

## Advanced Configuration

### Custom SSL Certificates

```bash
# Place certificates in
./virtualmin/etc/ssl/certs/your-cert.crt
./virtualmin/etc/ssl/private/your-cert.key

# Update Apache configuration
docker exec tkvmin virtualmin install-cert --domain example.com --cert /etc/ssl/certs/your-cert.crt --key /etc/ssl/private/your-cert.key
```

### Custom Apache Modules

```bash
# Enable additional modules
docker exec tkvmin a2enmod module_name
docker exec tkvmin systemctl reload apache2
```

### Custom PHP Configuration

```bash
# Edit PHP configuration
docker exec tkvmin nano /etc/php/8.2/fpm/php.ini

# Restart PHP-FPM
docker exec tkvmin systemctl restart php8.2-fpm
```

### Email Relay Configuration

```bash
# Configure Postfix relay
docker exec tkvmin postconf -e "relayhost = [smtp.example.com]:587"
docker exec tkvmin postconf -e "smtp_sasl_auth_enable = yes"
docker exec tkvmin postconf -e "smtp_sasl_password_maps = hash:/etc/postfix/sasl_passwd"

# Add credentials
docker exec tkvmin bash -c "echo '[smtp.example.com]:587 username:password' > /etc/postfix/sasl_passwd"
docker exec tkvmin postmap /etc/postfix/sasl_passwd
docker exec tkvmin systemctl reload postfix
```

## Support and Resources

### Official Documentation

- [Virtualmin Documentation](https://www.virtualmin.com/documentation)
- [Docker Documentation](https://docs.docker.com)
- [Apache Documentation](https://httpd.apache.org/docs/)
- [PHP Documentation](https://www.php.net/docs.php)

### Community Support

- Virtualmin Forums: <https://forum.virtualmin.com>
- Docker Community: <https://forums.docker.com>
- Stack Overflow: Tagged questions

### Monitoring Resources

- [Prometheus Documentation](https://prometheus.io/docs/)
- [Grafana Documentation](https://grafana.com/docs/)
- [Loki Documentation](https://grafana.com/docs/loki/)

### Backup Resources

- Backup strategies and best practices
- Disaster recovery planning
- Data retention policies

---

*Last Updated: 2025*
*Version: 2.0*
*Maintained by: Takelan Development*
