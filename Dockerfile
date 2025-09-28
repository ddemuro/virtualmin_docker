# Virtualmin Docker Image - Clean Architecture
FROM debian:bookworm AS runtime

ENV DEBIAN_FRONTEND=noninteractive \
    LANG=en_US.UTF-8 \
    LC_ALL=en_US.UTF-8

LABEL maintainer="Takelan Development" \
      description="Virtualmin Full Service Container" \
      homepage="www.takelan.com" \
      version="2.0"

WORKDIR /

# Install tini for proper init system and basic requirements
ADD https://github.com/krallin/tini/releases/download/v0.19.0/tini /tini
RUN chmod +x /tini && \
    apt-get update && \
    apt-get install -y --no-install-recommends \
        supervisor \
        systemd \
        systemd-sysv \
        dbus \
        curl \
        wget \
        ca-certificates \
        gnupg \
        lsb-release && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Copy systemctl replacement
COPY docker_fixes/systemctl.py /usr/bin/systemctl
RUN chmod +x /usr/bin/systemctl

# Copy APT sources and keyrings
COPY virtualmin/etc/apt/ /etc/apt/
COPY virtualmin/usr/share/keyrings/ /usr/share/keyrings/

# Copy all setup scripts
COPY setup/*.sh /tmp/setup/
RUN chmod +x /tmp/setup/*.sh

# Run installation scripts
RUN echo "Installing packages..." && \
    /tmp/setup/install-packages.sh && \
    echo "Installing PHP versions..." && \
    /tmp/setup/install-php.sh && \
    echo "Configuring system..." && \
    /tmp/setup/configure-system.sh && \
    echo "Cleaning up..." && \
    rm -rf /tmp/setup/*.sh && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*




#
# Exposed Ports for the container
#

# Named / Bind9
EXPOSE 53/tcp
EXPOSE 53/udp
EXPOSE 953/tcp

# Apache2
EXPOSE 80/tcp
EXPOSE 443/tcp

# SSH
EXPOSE 22/tcp

# MySQL
EXPOSE 3306/tcp

# Postfix
EXPOSE 25/tcp
EXPOSE 587/tcp
EXPOSE 465/tcp

# Dovecot
EXPOSE 110/tcp
EXPOSE 995/tcp
EXPOSE 143/tcp
EXPOSE 993/tcp

# Virtualmin
EXPOSE 10000/tcp
EXPOSE 20000/tcp

# Copy runtime scripts and configurations
COPY setup/run.sh /usr/local/bin/run.sh
COPY setup/update-os.sh /usr/local/bin/update-os
COPY setup/update-virtualmin.sh /usr/local/bin/update-virtualmin
COPY setup/backup-container.sh /usr/local/bin/backup-container
COPY setup/restore-container.sh /usr/local/bin/restore-container
COPY setup/supervisord.conf /etc/supervisor/conf.d/virtualmin.conf

# Copy automated backup scripts
COPY setup/automated-backup.sh /usr/local/bin/automated-backup.sh
COPY setup/quick-backup.sh /usr/local/bin/quick-backup.sh
COPY setup/mysql-backup.sh /usr/local/bin/mysql-backup.sh
COPY setup/verify-backups.sh /usr/local/bin/verify-backups.sh
COPY setup/cleanup-backups.sh /usr/local/bin/cleanup-backups.sh
COPY setup/backup-report.sh /usr/local/bin/backup-report.sh
COPY setup/backup-cron /etc/cron.d/virtualmin-backup

# Make all scripts executable
RUN chmod +x /usr/local/bin/* && \
    chmod 644 /etc/cron.d/virtualmin-backup

# Create backup directories
RUN mkdir -p /backups/{daily,weekly,monthly,quick,mysql} && \
    chmod 755 /backups

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5m --retries=3 \
    CMD curl -f http://localhost/server-status || exit 1

# Use tini as PID 1 to handle signals properly
ENTRYPOINT ["/tini", "--"]

# Default command runs supervisor
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/supervisord.conf"]
