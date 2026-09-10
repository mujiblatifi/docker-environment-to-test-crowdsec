#!/bin/bash

set -e

echo "=========================================="
echo " Kali Linux Attacker"
echo " Hostname: $(hostname)"
echo "=========================================="

# Determine which attacker network we are on.
ATTACKER_IP=$(ip -4 addr show | \
    awk '/inet / {print $2}' | \
    grep -E '^(172\.31\.0\.|192\.168\.255\.)' | \
    cut -d/ -f1 | \
    head -n1)

echo "[*] Attacker IP: $ATTACKER_IP"

if [[ "$ATTACKER_IP" == 192.168.255.* ]]; then

    echo "[*] Network: attackerNetA"
    echo "[*] Gateway: 192.168.255.254"

    # Route to the main CrowdSec service network.
    ip route add 10.10.10.0/24 via 192.168.255.254 || true

    # Route to attackerNetB.
    ip route add 172.31.0.0/24 via 192.168.255.254 || true

elif [[ "$ATTACKER_IP" == 172.31.0.* ]]; then

    echo "[*] Network: attackerNetB"
    echo "[*] Gateway: 172.31.0.254"

    # Route to the main CrowdSec service network.
    ip route add 10.10.10.0/24 via 172.31.0.254 || true

    # Route to attackerNetA.
    ip route add 192.168.255.0/24 via 172.31.0.254 || true

else

    echo "[!] Could not determine attacker network"
    exit 1

fi

echo
echo "[*] Network interfaces:"
ip addr

echo
echo "[*] Routing table:"
ip route

echo
echo "=========================================="
echo " Attacker is ready"
echo "=========================================="

exec tail -f /dev/null
