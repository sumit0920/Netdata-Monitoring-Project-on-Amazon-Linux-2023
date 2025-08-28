# Netdata Monitoring Project on Amazon Linux 2023

This project demonstrates how to install, configure, and test [Netdata](https://www.netdata.cloud/), a powerful real-time monitoring and troubleshooting tool.  
We will:
- Install Netdata on an Amazon Linux 2023 EC2 instance.
- View system metrics (CPU, memory, disk I/O) via the web dashboard.
- Add a **custom chart** using a `charts.d` plugin.
- Create a **health alarm** to trigger when CPU usage exceeds 80%.
- Test the dashboard with a system load generator.
- Automate the entire setup with shell scripts.

---

*Figure: EC2 instance running Netdata, dashboard accessible via browser (port 19999). Custom chart and health alarm configured.*

---

## **1. Manual Setup (Understand Before Automating)**

### Launch EC2 Instance
- **AMI:** Amazon Linux 2023 (64-bit)  
- **Type:** t2.small or similar  
- **Security Group:** open **TCP 19999** only from your IP (not 0.0.0.0/0).

### Install prerequisites
```bash
sudo dnf -y update
sudo dnf -y install curl gzip tar procps-ng jq which
````

### Install Netdata (kickstart installer)

```bash
wget -O /tmp/netdata-kickstart.sh https://get.netdata.cloud/kickstart.sh && sh /tmp/netdata-kickstart.sh --nightly-channel
```

Verify:

```bash
systemctl status netdata
```

If not running, see fallback instructions in `setup.sh`.

### Access Dashboard

Open in browser:

```
http://<EC2_PUBLIC_IP>:19999/
```

---

## **2. Custom Chart**

We’ll add a simple plugin to count SSHD processes.

```bash
sudo mkdir -p /usr/libexec/netdata/charts.d

sudo tee /usr/libexec/netdata/charts.d/process_count.chart.sh > /dev/null <<'EOF'
#!/usr/bin/env bash
if [ "$1" = "autoconf" ]; then
  echo yes
  exit 0
fi
if [ "$1" = "config" ]; then
  cat <<CFG
CHART process_count.sshd '' "sshd process count" "processes" "process_count" line 10000 1
DIMENSION count '' absolute 1 1
CFG
  exit 0
fi
c=$(pgrep -c sshd || echo 0)
echo "BEGIN process_count.sshd 1"
echo "SET count = $c"
echo "END"
EOF

sudo chmod +x /usr/libexec/netdata/charts.d/process_count.chart.sh
sudo nano /etc/netdata/charts.d.conf    # set "enabled = yes"
sudo systemctl restart netdata
```

View the new chart: **`process_count.sshd`** in the dashboard.

---

## **3. CPU Usage Alarm**

Create a health alert that warns if CPU usage > 80%:

```bash
sudo mkdir -p /etc/netdata/health.d
sudo tee /etc/netdata/health.d/cpu_high_usage.conf > /dev/null <<'EOF'
template: 10s_cpu_usage_high
on: system.cpu
lookup: average -1m user
units: %
every: 10s
warn: $this > 80
crit: $this > 95
to: sysadmin
rearm: $this < 70
info: "CPU user usage is above 80% threshold."
EOF

sudo netdatacli reload-health
```

---

## **4. Test the Monitoring Setup**

Generate CPU load to trigger the alarm:

```bash
sudo dnf install -y stress-ng || sudo dnf install -y stress
stress-ng --cpu 2 --timeout 60
```

If stress tools are unavailable:

```bash
yes > /dev/null & 
yes > /dev/null &
# kill later with: pkill yes
```

Open the Netdata dashboard to see CPU spike and alarm trigger in **Health**.

---

## **5. Automate with Scripts**

This repo contains:

* **`setup.sh`** – installs Netdata, adds custom chart & CPU alarm.
* **`test_dashboard.sh`** – generates load to test the dashboard.
* **`cleanup.sh`** – stops Netdata and removes added files.

### Usage:

```bash
chmod +x setup.sh test_dashboard.sh cleanup.sh

# Install & configure everything
sudo ./setup.sh

# Generate load for 2 minutes
sudo ./test_dashboard.sh 120

# Stop and clean up
sudo ./cleanup.sh
```

---

## **6. Diagram**

### **High-level flow:**

```
+---------------------+           +----------------------------+
|   Web Browser        | <-------> | EC2 Instance (Amazon Linux) |
|  (Port 19999)        |           | - Netdata Agent             |
|                     |           | - Custom charts.d plugin    |
+---------------------+           | - CPU Health Alarm          |
                                   +----------------------------+
```

* Netdata collects metrics in real time.
* Custom plugin shows SSHD process count.
* Alarm triggers if CPU > 80%.
* Port 19999 must be open in Security Group (restricted to your IP).

---

## **7. Cleanup**

To remove manually:

```bash
sudo systemctl stop netdata
sudo dnf remove -y netdata
sudo rm -f /usr/libexec/netdata/charts.d/process_count.chart.sh
sudo rm -f /etc/netdata/health.d/cpu_high_usage.conf
```

Or just run:

```bash
sudo ./cleanup.sh
```

---

## **8. Next Steps**

* Add authentication or reverse proxy (NGINX) to protect dashboard.
* Integrate with **Netdata Cloud** for secure remote access.
* Convert to Terraform or CloudFormation to fully automate deployment.
* Extend plugins to monitor application metrics (e.g., NGINX, MySQL).

---

## **References**

* [Netdata Installation Guide](https://learn.netdata.cloud/docs/installing)
* [Charts.d Plugin Documentation](https://learn.netdata.cloud/docs/agent/collectors/charts.d.plugin)
* [Health and Alerts Documentation](https://learn.netdata.cloud/docs/agent/health)

```
