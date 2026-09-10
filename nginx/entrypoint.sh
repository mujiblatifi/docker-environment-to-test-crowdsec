#!/bin/bash

set -e

echo "=========================================="
echo " NGINX + CrowdSec"
echo "=========================================="

# ============================================================
# NETWORK
# ============================================================

echo
echo "[*] Configuring routes"

ip route add 172.16.0.0/24 via 10.10.10.254 2>/dev/null || true
ip route add 192.168.255.0/24 via 10.10.10.254 2>/dev/null || true

echo
echo "[*] Routing table"
ip route

# ============================================================
# NGINX LOGS
# ============================================================

echo
echo "[*] Preparing NGINX logs"

mkdir -p /var/log/nginx

touch /var/log/nginx/access.log
touch /var/log/nginx/error.log

# ============================================================
# NGINX CONFIGURATION
# ============================================================

echo
echo "[*] Testing NGINX configuration"

nginx -t

# ============================================================
# RSYSLOG
# ============================================================

echo
echo "[*] Configuring rsyslog"

mkdir -p /var/spool/rsyslog
mkdir -p /var/log

cat > /etc/rsyslog.conf <<'EOF'
global(workDirectory="/var/spool/rsyslog")

module(load="imuxsock")

*.* /var/log/syslog
EOF

touch /var/log/syslog

rm -f /run/rsyslogd.pid

rsyslogd

sleep 1

if ! pgrep -x rsyslogd >/dev/null; then
    echo "ERROR: rsyslog failed to start"
    exit 1
fi

echo "[+] rsyslog is running"

# ============================================================
# CROWDSEC DIRECTORIES
# ============================================================

echo
echo "[*] Preparing CrowdSec"

mkdir -p /etc/crowdsec/acquis.d
mkdir -p /var/lib/crowdsec/data
mkdir -p /run/crowdsec

rm -f /run/crowdsec.sock
rm -f /run/crowdsec.pid

# IMPORTANT:
# Do NOT delete local_api_credentials.yaml.
#
# CrowdSec config.yaml references this file as:
#
# /etc/crowdsec/local_api_credentials.yaml
#
# We create it BEFORE starting CrowdSec.

# ============================================================
# CROWDSEC HUB
# ============================================================

echo
echo "[*] Updating CrowdSec hub"

cscli hub update

echo
echo "[*] Installing Linux collection"

cscli collections install crowdsecurity/linux

echo
echo "[*] Installing NGINX collection"

cscli collections install crowdsecurity/nginx

# ============================================================
# NGINX ACQUISITION
# ============================================================

echo
echo "[*] Configuring CrowdSec acquisition"

cat > /etc/crowdsec/acquis.d/nginx.yaml <<'EOF'
filenames:
  - /var/log/nginx/access.log

labels:
  type: nginx
EOF

echo "[+] NGINX acquisition configured"

# ============================================================
# LOCAL API CREDENTIALS
# ============================================================

echo
echo "[*] Preparing CrowdSec Local API credentials"

if [ ! -s /etc/crowdsec/local_api_credentials.yaml ]; then

    echo "[*] Local API credentials do not exist yet"

    cscli machines add \
        "$(hostname)-local" \
        --auto \
        --force \
        --file /etc/crowdsec/local_api_credentials.yaml

fi

if [ ! -s /etc/crowdsec/local_api_credentials.yaml ]; then
    echo "ERROR: local_api_credentials.yaml was not created"
    exit 1
fi

chmod 600 /etc/crowdsec/local_api_credentials.yaml

echo "[+] Local API credentials ready"

# ============================================================
# VALIDATE CROWDSEC CONFIGURATION
# ============================================================

echo
echo "[*] Validating CrowdSec configuration"

crowdsec -c /etc/crowdsec/config.yaml -t

echo "[+] CrowdSec configuration is valid"

# ============================================================
# START CROWDSEC
# ============================================================

echo
echo "[*] Starting CrowdSec"

crowdsec -c /etc/crowdsec/config.yaml &

CROWDSEC_PID=$!

echo "[*] Waiting for CrowdSec Local API"

CROWDSEC_READY=0

for i in $(seq 1 30); do

    if ! kill -0 "$CROWDSEC_PID" 2>/dev/null; then
        echo "[-] CrowdSec exited during startup"
        wait "$CROWDSEC_PID" || true
        exit 1
    fi

    if curl -fsS http://127.0.0.1:8080/health >/dev/null 2>&1; then
        CROWDSEC_READY=1
        echo "[+] CrowdSec Local API is ready"
        break
    fi

    sleep 1

done

if [ "$CROWDSEC_READY" -ne 1 ]; then
    echo "[-] CrowdSec Local API did not become ready"

    if kill -0 "$CROWDSEC_PID" 2>/dev/null; then
        kill "$CROWDSEC_PID" 2>/dev/null || true
    fi

    exit 1
fi

# ============================================================
# CROWDSEC STATUS
# ============================================================

echo
echo "[*] CrowdSec version"

cscli version

echo
echo "[*] CrowdSec machines"

cscli machines list

echo
echo "[*] CrowdSec collections"

cscli collections list

echo
echo "[*] CrowdSec metrics"

cscli metrics || true

# ============================================================
# VERIFY NGINX LOG
# ============================================================

echo
echo "[*] NGINX access log"

ls -lh /var/log/nginx/access.log

# ============================================================
# START NGINX
# ============================================================

echo
echo "=========================================="
echo " NGINX server starting"
echo "=========================================="

exec nginx -g "daemon off;"
