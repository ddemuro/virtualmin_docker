# Virtualmin Docker - Full Service Container

A comprehensive Docker-based Virtualmin deployment that runs like a full Linux VM with ALL services integrated in a single container, plus monitoring and management interfaces.

## 🚀 Quick Start

```bash
# Clone the repository
git clone https://github.com/yourusername/virtualmin_docker.git
cd virtualmin_docker

# Start all services
docker compose up -d

# Check status
docker compose ps

# SSH into container
ssh root@localhost -p 2222
# Password: virtualmin
```

## 📋 Default Credentials

### Main Services

| Service | Username | Password | Access |
|---------|----------|----------|--------|
| **SSH** | `root` | `virtualmin` | `ssh root@localhost -p 2222` |
| **MySQL/MariaDB** | `root` | `virtualmin` | Port 3306 |
| **Virtualmin/Webmin** | `root` | Set on first login | https://localhost:10000 |
| **LDAP/SLAPD** | `cn=admin,dc=virtualmin,dc=local` | `virtualmin` | Port 389 |

### Management Interfaces

| Service | URL | Username | Password |
|---------|-----|----------|----------|
| **phpMyAdmin** | http://localhost:8081 | `root` | `virtualmin` |
| **phpLDAPadmin** | http://localhost:8082 | `cn=admin,dc=virtualmin,dc=local` | `virtualmin` |
| **Portainer** | http://localhost:9000 | Set on first access | Set on first access |

### Monitoring Stack

| Service | URL | Username | Password |
|---------|-----|----------|----------|
| **Grafana** | http://localhost:3001 | `admin` | `admin` |
| **Prometheus** | http://localhost:9090 | - | - |
| **AlertManager** | http://localhost:9093 | - | - |

## 🏗️ Architecture

### Main Virtualmin Container
The main container includes ALL services running like a full Linux server:
- **Web Server**: Apache with mod_php, mod_fcgid, mod_wsgi
- **PHP Versions**: 5.6, 7.0, 7.1, 7.2, 7.3, 7.4, 8.0, 8.1, 8.2, 8.3
- **Database**: MariaDB/MySQL
- **Directory Service**: OpenLDAP (SLAPD)
- **DNS Server**: BIND9
- **Mail Server**: Postfix (SMTP) + Dovecot (IMAP/POP3)
- **Security**: Fail2ban, ClamAV
- **Control Panel**: Virtualmin/Webmin/Usermin

### Support Containers
- **phpMyAdmin**: Database management interface
- **phpLDAPadmin**: LDAP directory management
- **Portainer**: Docker container management
- **Prometheus**: Metrics collection
- **Grafana**: Metrics visualization
- **Loki**: Log aggregation
- **AlertManager**: Alert routing

## 📁 Directory Structure

```
virtualmin_docker/
├── docker-compose.yml       # Main configuration (USE THIS ONE!)
├── README.md               # This file
├── virtualmin/             # Persistent data (mounted to container)
│   ├── etc/               # System configuration files
│   ├── var/               # Variable data (logs, mail, www)
│   ├── home/              # User home directories
│   ├── root/              # Root user directory
│   ├── opt/               # Optional software
│   └── usr/               # User programs
├── backups/               # Backup directory
├── monitoring/            # Monitoring configurations
│   ├── prometheus/        # Prometheus config & rules
│   ├── grafana/          # Grafana dashboards & datasources
│   ├── loki/             # Loki configuration
│   └── alertmanager/     # Alert routing rules
└── setup/                # Setup scripts

```

## 🔌 Port Mappings

### Core Services
| Service | Container Port | Host Port | Notes |
|---------|---------------|-----------|-------|
| SSH | 22 | 2222 | Secure Shell access (changed to avoid conflict) |
| HTTP | 80 | 80 | Web server |
| HTTPS | 443 | 443 | Secure web server |
| MySQL | 3306 | 3306 | Database server |
| LDAP | 389 | 389 | Directory service |
| LDAPS | 636 | 636 | Secure LDAP |
| DNS | 53 | 15353 | Domain name service (changed to avoid conflict) |
| Virtualmin | 10000 | 10000 | Control panel |
| Usermin | 20000 | 20000 | User panel |

### Mail Services
| Service | Container Port | Host Port | Notes |
|---------|---------------|-----------|-------|
| SMTP | 25 | 2525 | Mail delivery (changed to avoid conflict) |
| POP3 | 110 | 1110 | Mail retrieval (changed to avoid conflict) |
| IMAP | 143 | 1143 | Mail access (changed to avoid conflict) |
| SMTPS | 465 | 465 | Secure SMTP |
| Submission | 587 | 587 | Mail submission |
| IMAPS | 993 | 993 | Secure IMAP |
| POP3S | 995 | 995 | Secure POP3 |

### Management & Monitoring
| Service | Port | URL |
|---------|------|-----|
| phpMyAdmin | 8081 | http://localhost:8081 |
| phpLDAPadmin | 8082 | http://localhost:8082 |
| Portainer | 9000 | http://localhost:9000 |
| Prometheus | 9090 | http://localhost:9090 |
| Grafana | 3001 | http://localhost:3001 |
| Node Exporter | 9100 | http://localhost:9100 |
| cAdvisor | 8090 | http://localhost:8090 |
| Loki | 3100 | http://localhost:3100 |
| AlertManager | 9093 | http://localhost:9093 |

## 🛠️ Common Commands

### Container Management
```bash
# Start all services
docker compose up -d

# Stop all services
docker compose down

# Restart services
docker compose restart

# View logs
docker compose logs -f virtualmin

# View specific service logs
docker compose logs -f grafana
```

### Access Container
```bash
# SSH into container
ssh root@localhost -p 2222
# Password: virtualmin

# Execute command in container
docker exec virtualmin service apache2 status

# Interactive shell
docker exec -it virtualmin bash
```

### Service Management
```bash
# Inside container - check all services
docker exec virtualmin service --status-all

# Restart individual services
docker exec virtualmin service apache2 restart
docker exec virtualmin service mariadb restart
docker exec virtualmin service slapd restart
docker exec virtualmin service postfix restart
docker exec virtualmin service dovecot restart
docker exec virtualmin service bind9 restart
docker exec virtualmin service ssh restart
```

### Database Access
```bash
# MySQL CLI
docker exec virtualmin mysql -u root -pvirtualmin

# Run SQL command
docker exec virtualmin mysql -u root -pvirtualmin -e "SHOW DATABASES;"
```

### LDAP Access
```bash
# Search LDAP
docker exec virtualmin ldapsearch -x -h localhost -b "dc=virtualmin,dc=local"

# Add LDAP entry
docker exec virtualmin ldapadd -x -D "cn=admin,dc=virtualmin,dc=local" -w virtualmin -f entry.ldif
```

## 🔧 Configuration

### Environment Variables
The main configuration is in `docker-compose.yml`:

```yaml
environment:
  - MYSQL_ROOT_PASSWORD=virtualmin
  - SLAPD_PASSWORD=virtualmin
  - SLAPD_DOMAIN=virtualmin.local
  - SLAPD_ORGANISATION=Virtualmin
```

### Changing Default Passwords

1. **SSH/Root Password**:
```bash
docker exec -it virtualmin passwd root
```

2. **MySQL Password**:
```bash
docker exec virtualmin mysql -u root -pvirtualmin
mysql> ALTER USER 'root'@'%' IDENTIFIED BY 'newpassword';
mysql> FLUSH PRIVILEGES;
```

3. **LDAP Admin Password**:
```bash
docker exec virtualmin ldappasswd -D "cn=admin,dc=virtualmin,dc=local" -w virtualmin
```

4. **Update docker-compose.yml** with new passwords and restart

### Persistent Data
All configuration and data is stored in the `virtualmin/` folder:
- `virtualmin/etc/` - System configuration
- `virtualmin/var/` - Logs, mail, web files
- `virtualmin/home/` - User home directories
- `virtualmin/root/` - Root user files

## 📊 Monitoring

### Grafana Dashboards
Access at http://localhost:3001 (admin/admin)
- System Overview Dashboard
- Container Metrics Dashboard
- Apache Performance Dashboard
- MySQL Performance Dashboard

### Prometheus Metrics
Access at http://localhost:9090
- Node metrics from Node Exporter
- Container metrics from cAdvisor
- Apache metrics from Apache Exporter
- MySQL metrics from MySQL Exporter

### Logs with Loki
Centralized logging accessible through Grafana

## 🔒 Security

⚠️ **Important Security Steps**:

1. **Change all default passwords immediately**
2. **Configure firewall rules**
3. **Enable SSL/TLS for all services**
4. **Regular security updates**:
```bash
docker exec virtualmin apt-get update && apt-get upgrade
```

5. **Configure Fail2ban**:
```bash
docker exec virtualmin fail2ban-client status
```

## 🐛 Troubleshooting

### Container Won't Start
```bash
# Check for port conflicts
sudo netstat -tulpn | grep -E "(80|443|3306|2222)"

# Check Docker logs
docker compose logs virtualmin

# Remove and recreate
docker compose down
docker compose up -d
```

### Services Not Running
```bash
# Check service status inside container
docker exec virtualmin service --status-all

# Restart all services
docker exec virtualmin bash -c "
  service apache2 restart
  service mariadb restart
  service slapd restart
  service ssh restart
"
```

### Port Conflicts
Edit `docker-compose.yml` to change port mappings:
```yaml
ports:
  - "8080:80"    # Change HTTP to 8080
  - "8443:443"   # Change HTTPS to 8443
```

### Reset Everything
```bash
# Stop all containers
docker compose down -v

# Clean persistent data (WARNING: Deletes all data!)
sudo rm -rf virtualmin/var/* virtualmin/etc/* virtualmin/home/*

# Start fresh
docker compose up -d
```

### Known Issues

1. **Missing supervisord.conf**: Fixed in latest version. The main supervisord configuration file is now created from `setup/supervisord-main.conf`.

2. **Port Conflicts**: The following ports have been changed to avoid conflicts with system services:
   - SSH: Port 22 → 2222
   - SMTP: Port 25 → 2525
   - DNS: Port 53 → 15353
   - POP3: Port 110 → 1110
   - IMAP: Port 143 → 1143
   - cAdvisor: Port 8080 → 8090

3. **Container Health Checks**: The container uses Apache's `/server-status` endpoint for health monitoring. Services must start properly for the container to become healthy.

4. **Build Time**: Initial build takes 10-15 minutes to install all packages (Webmin, Virtualmin, Apache, PHP, MariaDB, mail servers, DNS, LDAP, etc.).

5. **Container Status "Restarting"**: If the container shows "restarting" status, check logs with `docker logs tkvmin` to identify which service is failing to start.

## 📝 Notes

- The main container runs like a full Linux VM with systemd replacement
- All services are managed by Virtualmin/Webmin interface
- Data persists in the `virtualmin/` folder structure
- Monitoring stack provides complete observability
- Regular backups are stored in the `backups/` directory

## 🤝 Contributing

Feel free to submit issues and pull requests.

## 📄 License

MIT License - See LICENSE file for details.