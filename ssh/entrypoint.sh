#!/bin/bash

set -e

echo "=========================================="
echo " Ubuntu SSH + CrowdSec"
echo "=========================================="

# ============================================================
# NETWORK
# ============================================================

echo "[*] Configuring routes"

ip route add 172.16.0.0/24 via 10.10.10.254 2>/dev/null || true
ip route add 192.168.255.0/24 via 10.10.10.254 2>/dev/null || true

echo
echo "[*] Routing table:"
ip route

# ============================================================
# SSH
# ============================================================

echo
echo "[*] Configuring SSH"

mkdir -p /run/sshd
mkdir -p /var/log

ssh-keygen -A

if ! id labuser >/dev/null 2>&1; then
    useradd -m -s /bin/bash labuser
fi

echo "labuser:labpassword" | chpasswd

touch /var/log/auth.log
chmod 640 /var/log/auth.log

# ============================================================
# RSYSLOG
# ============================================================

echo
echo "[*] Configuring rsyslog"

mkdir -p /var/spool/rsyslog

# Remove the kernel logging configuration because containers
# normally cannot access /proc/kmsg.
rm -f /etc/rsyslog.d/*kernel* 2>/dev/null || true

cat > /etc/rsyslog.conf <<'EOF'
global(workDirectory="/var/spool/rsyslog")

module(load="imuxsock")

auth,authpriv.*    /var/log/auth.log
EOF

rsyslogd

sleep 1

# ============================================================
# CROWDSEC
# ============================================================

echo
echo "[*] Preparing CrowdSec"

mkdir -p /etc/crowdsec/acquis.d
mkdir -p /var/lib/crowdsec/data
mkdir -p /run/crowdsec

rm -f /run/crowdsec.sock
rm -f /run/crowdsec.pid

# ============================================================
# VERIFY CONFIGURATION BEFORE CSCLI
# ============================================================

echo
echo "[*] Checking CrowdSec configuration"

if grep -q "online_api_credentials.yaml" /etc/crowdsec/config.yaml; then
    echo "ERROR: config.yaml still references online_api_credentials.yaml"
    exit 1
fi

echo "[+] Central API configuration disabled"

# ============================================================
# CROWDSEC HUB
# ============================================================

echo
echo "[*] Updating CrowdSec hub"

cscli hub update

echo
echo "[*] Installing Linux collection"

cscli collections install crowdsecurity/linux || true

echo
echo "[*] Installing SSHD collection"

cscli collections install crowdsecurity/sshd || true

# ============================================================
# LOCAL API CREDENTIALS
# ============================================================

echo
echo "[*] Creating CrowdSec Local API credentials"

if [ ! -s /etc/crowdsec/local_api_credentials.yaml ]; then
    rm -f /etc/crowdsec/local_api_credentials.yaml

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

echo "[+] Local API credentials created"

# ============================================================
# SSH LOG ACQUISITION
# ============================================================

echo
echo "[*] Configuring SSH log acquisition"

cat > /etc/crowdsec/acquis.d/sshd.yaml <<'EOF'
filenames:
  - /var/log/auth.log

labels:
  type: syslog
EOF

# ============================================================
# VALIDATE CROWDSEC
# ============================================================

echo
echo "[*] Validating CrowdSec configuration"

crowdsec -c /etc/crowdsec/config.yaml -t

# ============================================================
# START CROWDSEC
# ============================================================

echo
echo "[*] Starting CrowdSec"

crowdsec -c /etc/crowdsec/config.yaml &

CROWDSEC_PID=$!

sleep 5

if ! kill -0 "$CROWDSEC_PID" 2>/dev/null; then
    echo "ERROR: CrowdSec failed to start"
    exit 1
fi

echo "[+] CrowdSec is running"

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
# SSH LOG CHECK
# ============================================================

echo
echo "[*] SSH authentication log"

ls -l /var/log/auth.log

# ============================================================
# START SSH
# ============================================================

echo
echo "=========================================="
echo " SSH server starting"
echo "=========================================="

exec /usr/sbin/sshd -D -e
