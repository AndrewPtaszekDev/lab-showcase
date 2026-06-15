#!/bin/bash

# Variables - Update version if needed
VERSION="1.8.2"
USER="node_exporter"
BIN_DIR="/usr/local/bin"
ARCH=$(uname -m)

# Adjust architecture naming for Prometheus binaries
if [ "$ARCH" == "x86_64" ]; then
    ARCH="amd64"
elif [ "$ARCH" == "aarch64" ]; then
    ARCH="arm64"
fi

echo "--- Starting Node Exporter Installation (v$VERSION) ---"

# 1. Create a system user (no login shell)
if ! id "$USER" &>/dev/null; then
    sudo useradd --no-create-home --shell /bin/false $USER
    echo "User $USER created."
fi

# 2. Download and Extract
cd /tmp
wget https://github.com/prometheus/node_exporter/releases/download/v${VERSION}/node_exporter-${VERSION}.linux-${ARCH}.tar.gz
tar -xvf node_exporter-${VERSION}.linux-${ARCH}.tar.gz

# 3. Move binary and set permissions
sudo mv node_exporter-${VERSION}.linux-${ARCH}/node_exporter $BIN_DIR
sudo chown $USER:$USER $BIN_DIR/node_exporter

# 4. Create Systemd Service File
sudo bash -c "cat <<EOF > /etc/systemd/system/node_exporter.service
[Unit]
Description=Node Exporter
Wants=network-online.target
After=network-online.target

[Service]
User=$USER
Group=$USER
Type=simple
ExecStart=$BIN_DIR/node_exporter

[Install]
WantedBy=multi-user.target
EOF"

# 5. Reload systemd and start service
sudo systemctl daemon-reload
sudo systemctl enable node_exporter
sudo systemctl start node_exporter

echo "--- Installation Complete ---"
echo "Status:"
sudo systemctl status node_exporter --no-pager
echo "Node Exporter is running on port 9100"
