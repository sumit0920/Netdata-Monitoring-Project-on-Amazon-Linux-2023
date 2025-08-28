#!/bin/bash
# test_dashboard.sh - Generate CPU load to test Netdata alert

set -e

echo "Installing stress tool..."
if [ -f /etc/debian_version ]; then
    sudo apt install stress -y
elif [ -f /etc/redhat-release ]; then
    sudo dnf install stress -y
fi

echo "Generating CPU load for 1 minute..."
stress --cpu 4 --timeout 60

echo "Test complete. Check your Netdata dashboard for alerts."
