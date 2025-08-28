#!/bin/bash
# setup.sh - Install Netdata and configure basic settings

set -e

echo "Updating system..."
if [ -f /etc/debian_version ]; then
    sudo apt update && sudo apt upgrade -y
elif [ -f /etc/redhat-release ]; then
    sudo dnf update -y
fi

echo "Installing Netdata..."
wget -O /tmp/netdata-kickstart.sh https://get.netdata.cloud/kickstart.sh && sh /tmp/netdata-kickstart.sh --nightly-channel

echo "Configuring Netdata..."
sudo sed -i 's/# bind to = localhost/bind to = */' /etc/netdata/netdata.conf || true
sudo mkdir -p /etc/netdata/health.d

cat <<EOF | sudo tee /etc/netdata/health.d/cpu.conf
alarm: cpu_usage_high
    on: system.cpu
    lookup: average -1m unaligned of user,system,softirq,irq
    units: %
    every: 10s
    warn: \$this > 80
    crit: \$this > 90
    info: CPU usage above 80%
EOF

echo "Restarting Netdata..."
sudo systemctl restart netdata

echo "Netdata setup complete. Access dashboard at http://<server-ip>:19999"
