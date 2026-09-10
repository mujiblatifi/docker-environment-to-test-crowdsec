#!/bin/sh

set -e

echo "=========================================="
echo " Docker Lab Router"
echo "=========================================="

echo
echo "[*] Interfaces:"
ip addr

echo
echo "[*] Routing table:"
ip route

echo
echo "[*] Checking IPv4 forwarding:"

FORWARDING=$(cat /proc/sys/net/ipv4/ip_forward)

echo "net.ipv4.ip_forward = $FORWARDING"

if [ "$FORWARDING" != "1" ]; then
    echo
    echo "ERROR: IPv4 forwarding is not enabled."
    echo "Check the net.ipv4.ip_forward setting in compose.yml."
    exit 1
fi

echo
echo "[*] IPv4 forwarding is enabled."

echo
echo "=========================================="
echo " Router is ready"
echo "=========================================="

# Keep the container running.
exec tail -f /dev/null
