#!/bin/bash
# Backup Report Generation Script

set -e

BACKUP_ROOT="${BACKUP_ROOT:-/backups}"
REPORT_FILE="${BACKUP_ROOT}/backup-report-$(date +%Y%m%d).html"
ALERT_EMAIL="${ALERT_EMAIL:-admin@example.com}"

echo "Generating backup report..."

# Start HTML report
cat > "$REPORT_FILE" << 'EOF'
<!DOCTYPE html>
<html>
<head>
    <title>Backup Report</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        h1 { color: #333; border-bottom: 2px solid #0066cc; }
        h2 { color: #0066cc; margin-top: 30px; }
        table { border-collapse: collapse; width: 100%; margin: 20px 0; }
        th { background-color: #0066cc; color: white; padding: 10px; text-align: left; }
        td { border: 1px solid #ddd; padding: 8px; }
        tr:nth-child(even) { background-color: #f2f2f2; }
        .success { color: green; font-weight: bold; }
        .warning { color: orange; font-weight: bold; }
        .error { color: red; font-weight: bold; }
        .summary { background: #f0f0f0; padding: 15px; border-radius: 5px; margin: 20px 0; }
        .metric { display: inline-block; margin: 10px 20px; }
        .metric-value { font-size: 24px; font-weight: bold; color: #0066cc; }
        .metric-label { color: #666; }
    </style>
</head>
<body>
EOF

# Add report header
cat >> "$REPORT_FILE" << EOF
<h1>Backup Report - $(hostname)</h1>
<p>Generated: $(date)</p>

<div class="summary">
    <h2>Summary Statistics</h2>
    <div class="metric">
        <div class="metric-value">$(find ${BACKUP_ROOT}/daily -type f -mtime -1 2>/dev/null | wc -l)</div>
        <div class="metric-label">Daily Backups (24h)</div>
    </div>
    <div class="metric">
        <div class="metric-value">$(du -sh ${BACKUP_ROOT} 2>/dev/null | cut -f1)</div>
        <div class="metric-label">Total Size</div>
    </div>
    <div class="metric">
        <div class="metric-value">$(df -h ${BACKUP_ROOT} | awk 'NR==2 {print $5}')</div>
        <div class="metric-label">Disk Usage</div>
    </div>
    <div class="metric">
        <div class="metric-value">$(df -h ${BACKUP_ROOT} | awk 'NR==2 {print $4}')</div>
        <div class="metric-label">Free Space</div>
    </div>
</div>

<h2>Recent Backups (Last 24 Hours)</h2>
<table>
<tr>
    <th>Backup File</th>
    <th>Size</th>
    <th>Created</th>
    <th>Age</th>
    <th>Status</th>
</tr>
EOF

# List recent backups
find ${BACKUP_ROOT}/daily -type f -mtime -1 2>/dev/null | while read backup; do
    filename=$(basename "$backup")
    size=$(du -h "$backup" | cut -f1)
    created=$(stat -c %y "$backup" | cut -d'.' -f1)
    age_hours=$(( ($(date +%s) - $(stat -c %Y "$backup")) / 3600 ))

    # Check integrity
    if gzip -t "$backup" 2>/dev/null || tar -tzf "$backup" >/dev/null 2>&1; then
        status='<span class="success">✓ Valid</span>'
    else
        status='<span class="error">✗ Corrupted</span>'
    fi

    cat >> "$REPORT_FILE" << EOF
<tr>
    <td>$filename</td>
    <td>$size</td>
    <td>$created</td>
    <td>${age_hours} hours</td>
    <td>$status</td>
</tr>
EOF
done

# Add backup history section
cat >> "$REPORT_FILE" << EOF
</table>

<h2>Backup History (Last 7 Days)</h2>
<table>
<tr>
    <th>Date</th>
    <th>Daily</th>
    <th>MySQL</th>
    <th>Config</th>
    <th>Total Size</th>
</tr>
EOF

# Generate history for last 7 days
for i in {0..6}; do
    date_check=$(date -d "$i days ago" +%Y%m%d)
    date_display=$(date -d "$i days ago" +"%Y-%m-%d")

    daily_count=$(find ${BACKUP_ROOT}/daily -name "*${date_check}*" 2>/dev/null | wc -l)
    mysql_count=$(find ${BACKUP_ROOT}/mysql -name "*${date_check}*" 2>/dev/null | wc -l)
    config_count=$(find ${BACKUP_ROOT}/quick -name "*${date_check}*" 2>/dev/null | wc -l)

    if [ $daily_count -gt 0 ] || [ $mysql_count -gt 0 ] || [ $config_count -gt 0 ]; then
        total_size=$(find ${BACKUP_ROOT} -name "*${date_check}*" -exec du -ch {} + 2>/dev/null | grep total | cut -f1)
    else
        total_size="0"
    fi

    cat >> "$REPORT_FILE" << EOF
<tr>
    <td>$date_display</td>
    <td>$daily_count</td>
    <td>$mysql_count</td>
    <td>$config_count</td>
    <td>$total_size</td>
</tr>
EOF
done

# Add service-specific backup status
cat >> "$REPORT_FILE" << EOF
</table>

<h2>Service Backup Status</h2>
<table>
<tr>
    <th>Service</th>
    <th>Last Backup</th>
    <th>Size</th>
    <th>Status</th>
</tr>
EOF

# Check each service
for service in "mysql" "virtualmin" "websites" "mail" "apache" "php" "ssl" "dns"; do
    latest=$(find ${BACKUP_ROOT}/daily -name "${service}-*" 2>/dev/null | xargs ls -t 2>/dev/null | head -1)

    if [ -n "$latest" ]; then
        last_backup=$(stat -c %y "$latest" | cut -d'.' -f1)
        size=$(du -h "$latest" | cut -f1)
        age_hours=$(( ($(date +%s) - $(stat -c %Y "$latest")) / 3600 ))

        if [ $age_hours -lt 26 ]; then
            status='<span class="success">Current</span>'
        elif [ $age_hours -lt 48 ]; then
            status='<span class="warning">Aging</span>'
        else
            status='<span class="error">Old</span>'
        fi
    else
        last_backup="Never"
        size="N/A"
        status='<span class="error">Missing</span>'
    fi

    cat >> "$REPORT_FILE" << EOF
<tr>
    <td>$(echo $service | tr '[:lower:]' '[:upper:]')</td>
    <td>$last_backup</td>
    <td>$size</td>
    <td>$status</td>
</tr>
EOF
done

# Add disk usage trend
cat >> "$REPORT_FILE" << EOF
</table>

<h2>Storage Analysis</h2>
<table>
<tr>
    <th>Backup Type</th>
    <th>Count</th>
    <th>Total Size</th>
    <th>Oldest</th>
    <th>Newest</th>
</tr>
EOF

for dir in "daily" "weekly" "monthly" "quick" "mysql"; do
    if [ -d "${BACKUP_ROOT}/${dir}" ]; then
        count=$(find ${BACKUP_ROOT}/${dir} -type f 2>/dev/null | wc -l)
        if [ $count -gt 0 ]; then
            size=$(du -sh ${BACKUP_ROOT}/${dir} 2>/dev/null | cut -f1)
            oldest=$(find ${BACKUP_ROOT}/${dir} -type f -printf '%T+ %p\n' 2>/dev/null | sort | head -1 | cut -d' ' -f1 | cut -d'.' -f1)
            newest=$(find ${BACKUP_ROOT}/${dir} -type f -printf '%T+ %p\n' 2>/dev/null | sort -r | head -1 | cut -d' ' -f1 | cut -d'.' -f1)
        else
            size="0"
            oldest="N/A"
            newest="N/A"
        fi
    else
        count=0
        size="0"
        oldest="N/A"
        newest="N/A"
    fi

    cat >> "$REPORT_FILE" << EOF
<tr>
    <td>$(echo $dir | tr '[:lower:]' '[:upper:]')</td>
    <td>$count</td>
    <td>$size</td>
    <td>$oldest</td>
    <td>$newest</td>
</tr>
EOF
done

# Check for any errors in logs
error_count=$(grep -c ERROR ${BACKUP_ROOT}/backup.log 2>/dev/null || echo "0")
warning_count=$(grep -c WARNING ${BACKUP_ROOT}/backup.log 2>/dev/null || echo "0")

# Complete the HTML
cat >> "$REPORT_FILE" << EOF
</table>

<h2>Recent Log Messages</h2>
<div style="background: #f5f5f5; padding: 10px; border: 1px solid #ddd; font-family: monospace; font-size: 12px;">
$(tail -20 ${BACKUP_ROOT}/backup.log 2>/dev/null | sed 's/</\&lt;/g;s/>/\&gt;/g;s/$/<br>/')
</div>

<div class="summary">
    <h3>Status Summary</h3>
    <p>Errors in last 24h: <span class="$([ $error_count -eq 0 ] && echo 'success' || echo 'error')">$error_count</span></p>
    <p>Warnings in last 24h: <span class="$([ $warning_count -eq 0 ] && echo 'success' || echo 'warning')">$warning_count</span></p>
</div>

</body>
</html>
EOF

echo "Report generated: $REPORT_FILE"

# Send report via email if configured
if [ -n "$ALERT_EMAIL" ] && [ "$ALERT_EMAIL" != "admin@example.com" ]; then
    # Create text version for email
    TEXT_REPORT="${BACKUP_ROOT}/backup-report-$(date +%Y%m%d).txt"

    cat > "$TEXT_REPORT" << EOF
BACKUP REPORT - $(hostname)
Generated: $(date)
=====================================

SUMMARY STATISTICS
- Daily Backups (24h): $(find ${BACKUP_ROOT}/daily -type f -mtime -1 2>/dev/null | wc -l)
- Total Size: $(du -sh ${BACKUP_ROOT} 2>/dev/null | cut -f1)
- Disk Usage: $(df -h ${BACKUP_ROOT} | awk 'NR==2 {print $5}')
- Free Space: $(df -h ${BACKUP_ROOT} | awk 'NR==2 {print $4}')

RECENT ERRORS: $error_count
RECENT WARNINGS: $warning_count

For full report, see: $REPORT_FILE
EOF

    cat "$TEXT_REPORT" | mail -s "Weekly Backup Report - $(hostname)" "$ALERT_EMAIL" 2>/dev/null || true
    echo "Report emailed to $ALERT_EMAIL"
fi