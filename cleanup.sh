#!/bin/bash
# cleanup.sh - Remove Netdata from system

set -e

echo "Stopping Netdata..."
sudo systemctl stop netdata

echo "Removing Netdata..."
sudo systemctl disable netdata
sudo rm -rf /etc/netdata /usr/libexec/netdata /usr/sbin/netdata /var/lib/netdata /usr/lib/netdata /usr/share/netdata

echo "Cleanup complete. Netdata removed from system."
