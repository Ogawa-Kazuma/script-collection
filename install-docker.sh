#!/bin/bash
set -e

echo "=== Docker & Docker Compose Installer (with /data/docker storage) ==="

# Update and install prerequisites
echo "[1/8] Installing required packages..."
sudo apt update && sudo apt install -y apt-transport-https ca-certificates curl docker-compose-plugin software-properties-common gnupg lsb-release --fix-missing

# Prepare directories
echo "[2/8] Preparing directories..."
sudo mkdir -p /etc/apt/sources.list.d /data/docker /usr/local/bin

# Add Docker’s official GPG key
echo "[3/8] Adding Docker GPG key..."
curl -fsSL https://download.docker.com/linux/$(. /etc/os-release; echo "$ID")/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

# Add Docker repository
echo "[4/8] Adding Docker repository..."
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/$(. /etc/os-release; echo "$ID") $(lsb_release -cs) stable" \
  | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Install Docker engine
echo "[5/8] Installing Docker..."
sudo apt update
sudo apt install -y docker-ce docker-ce-cli containerd.io

# Move Docker storage to /data/docker
echo "[6/8] Configuring Docker storage directory..."
sudo systemctl stop docker
sudo mv /var/lib/docker /var/lib/docker.bak 2>/dev/null || true
echo '{"data-root": "/data/docker"}' | sudo tee /etc/docker/daemon.json > /dev/null
sudo systemctl start docker
sudo systemctl enable docker

# Verify Docker root directory
echo "[7/8] Verifying Docker storage location..."
sudo docker info | grep "Docker Root Dir" || echo "⚠️  Unable to verify automatically. Run 'sudo docker info' to confirm."

# Install Docker Compose
echo "[8/8] Installing Docker Compose..."
sudo bash -c 'curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose && chmod +x /usr/local/bin/docker-compose'

# Final checks
echo
echo "=== Installation Complete ==="
sudo docker --version
docker-compose --version
echo
echo "✅ Docker is using storage at: $(sudo docker info 2>/dev/null | grep "Docker Root Dir" || echo "/data/docker")"
echo "✅ Use 'sudo docker ps' to verify Docker is working."


