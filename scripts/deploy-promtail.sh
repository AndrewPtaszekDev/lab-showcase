#!/bin/bash
set -e

#########################################
# Promtail Deployment Script
# Deploys Promtail as a systemd service on host machines
#########################################

# Configuration
PROMTAIL_VERSION="3.0.0"
LOKI_URL="http://DOCKER_HOST_IP:3100"
INSTALL_DIR="/usr/local/bin"
CONFIG_DIR="/etc/promtail"
DATA_DIR="/var/lib/promtail"
LOG_DIR="/var/log"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    print_error "Please run as root (use sudo)"
    exit 1
fi

print_info "Starting Promtail deployment..."

# Detect architecture
ARCH=$(uname -m)
case $ARCH in
    x86_64)
        PROMTAIL_ARCH="amd64"
        ;;
    aarch64|arm64)
        PROMTAIL_ARCH="arm64"
        ;;
    armv7l)
        PROMTAIL_ARCH="armv7"
        ;;
    *)
        print_error "Unsupported architecture: $ARCH"
        exit 1
        ;;
esac

print_info "Detected architecture: $ARCH (using $PROMTAIL_ARCH binary)"

# Create directories
print_info "Creating directories..."
mkdir -p "$CONFIG_DIR"
mkdir -p "$DATA_DIR"

# Download Promtail binary
print_info "Downloading Promtail v${PROMTAIL_VERSION}..."
DOWNLOAD_URL="https://github.com/grafana/loki/releases/download/v${PROMTAIL_VERSION}/promtail-linux-${PROMTAIL_ARCH}.zip"

cd /tmp
wget -q --show-progress "$DOWNLOAD_URL" -O promtail.zip

if [ $? -ne 0 ]; then
    print_error "Failed to download Promtail"
    exit 1
fi

# Extract and install
print_info "Installing Promtail binary..."
unzip -o promtail.zip
chmod +x promtail-linux-${PROMTAIL_ARCH}
mv promtail-linux-${PROMTAIL_ARCH} ${INSTALL_DIR}/promtail
rm -f promtail.zip

# Get hostname for job labeling
HOSTNAME=$(hostname)

# Create Promtail configuration
print_info "Creating Promtail configuration..."
cat > ${CONFIG_DIR}/config.yml <<EOF
server:
  http_listen_port: 9080
  grpc_listen_port: 0

positions:
  filename: ${DATA_DIR}/positions.yaml

clients:
  - url: ${LOKI_URL}/loki/api/v1/push

scrape_configs:
  # Scrape system logs
  - job_name: system
    static_configs:
      - targets:
          - localhost
        labels:
          job: varlogs
          host: ${HOSTNAME}
          __path__: /var/log/*log

  # Scrape journald logs
  - job_name: journal
    journal:
      max_age: 12h
      labels:
        job: systemd-journal
        host: ${HOSTNAME}
    relabel_configs:
      - source_labels: ['__journal__systemd_unit']
        target_label: 'unit'

  # Optional: Scrape Docker container logs if Docker is installed
  # Uncomment if you want to scrape Docker logs from this host
  # - job_name: docker
  #   static_configs:
  #     - targets:
  #         - localhost
  #       labels:
  #         job: docker
  #         host: ${HOSTNAME}
  #         __path__: /var/lib/docker/containers/*/*-json.log
  #   pipeline_stages:
  #     - json:
  #         expressions:
  #           output: log
  #           stream: stream
  #           attrs:
  #     - labels:
  #         stream:
  #     - output:
  #         source: output
EOF

# Create systemd service file
print_info "Creating systemd service..."
cat > /etc/systemd/system/promtail.service <<EOF
[Unit]
Description=Promtail Log Collector
Documentation=https://grafana.com/docs/loki/latest/clients/promtail/
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
User=root
ExecStart=${INSTALL_DIR}/promtail -config.file=${CONFIG_DIR}/config.yml
Restart=on-failure
RestartSec=10s

# Security settings
NoNewPrivileges=true
ProtectSystem=strict
ProtectHome=true
ReadWritePaths=${DATA_DIR}
ReadOnlyPaths=/var/log /var/lib/docker/containers

# Resource limits
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target
EOF

# Reload systemd and enable service
print_info "Enabling Promtail service..."
systemctl daemon-reload
systemctl enable promtail.service

# Start the service
print_info "Starting Promtail service..."
systemctl start promtail.service

# Wait a moment for service to start
sleep 2

# Check service status
if systemctl is-active --quiet promtail.service; then
    print_info "✓ Promtail deployed successfully!"
    print_info "Service status:"
    systemctl status promtail.service --no-pager -l
else
    print_error "Promtail service failed to start"
    print_error "Check logs with: journalctl -u promtail.service -n 50"
    exit 1
fi

print_info ""
print_info "Deployment complete!"
print_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
print_info "Configuration file: ${CONFIG_DIR}/config.yml"
print_info "Positions file: ${DATA_DIR}/positions.yaml"
print_info "Loki URL: ${LOKI_URL}"
print_info ""
print_info "Useful commands:"
print_info "  Check status:  sudo systemctl status promtail"
print_info "  View logs:     sudo journalctl -u promtail -f"
print_info "  Restart:       sudo systemctl restart promtail"
print_info "  Stop:          sudo systemctl stop promtail"
print_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
