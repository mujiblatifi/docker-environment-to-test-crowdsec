#!/bin/bash

set -e

echo "=========================================="
echo " Kali Linux Attacker"
echo " Hostname: $(hostname)"
echo "=========================================="

# Determine which attacker network we are on
ATTACKER_IP=$(ip -4 addr show | \
    awk '/inet / {print $2}' | \
    grep -E '192\.168\.255\.|172\.16\.' | \
    cut -d/ -f1 | \
    head -n1)

echo "[*] Attacker IP: $ATTACKER_IP"

if [[ "$ATTACKER_IP" == 192.168.255.* ]]; then

    echo "[*] Network: attackerNetA"

    ip route add 10.10.10.0/24 via 192.168.255.254 || true
    ip route add 172.16.0.0/24 via 192.168.255.254 || true

elif [[ "$ATTACKER_IP" == 172.16.* ]]; then

    echo "[*] Network: attackerNetB"

    ip route add 10.10.10.0/24 via 172.16.0.254 || true
    ip route add 192.168.255.0/24 via 172.16.0.254 || true

else

    echo "[!] Could not determine attacker network"

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
