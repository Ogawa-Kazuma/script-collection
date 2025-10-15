#!/bin/bash

set -e

echo "=== 🧩 Installing Tailscale inside Docker (with /data persistence) ==="

# --- Step 1: Prerequisites ---
if ! command -v docker &> /dev/null; then
  echo "Installing Docker..."
  apt update && apt install -y apt-transport-https ca-certificates curl gnupg lsb-release
  curl -fsSL https://download.docker.com/linux/$(. /etc/os-release; echo "$ID")/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker.gpg
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker.gpg] https://download.docker.com/linux/$(. /etc/os-release; echo "$ID") $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
  apt update && apt install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
  systemctl enable docker
  systemctl start docker
fi

if ! command -v docker compose &> /dev/null; then
  echo "Installing docker-compose-plugin..."
  apt install -y docker-compose-plugin
fi

# --- Step 2: Create /data/tailscale structure ---
echo "Setting up Tailscale data directory..."
sudo mkdir -p /data/tailscale/state

# --- Step 3: Generate docker-compose.yml ---
cat > /data/tailscale/docker-compose.yml <<'EOF'
version: "3.8"

services:
  tailscale:
    image: tailscale/tailscale:latest
    container_name: tailscale
    hostname: tailscale-docker
    restart: unless-stopped
    network_mode: "host"
    privileged: true
    volumes:
      - /data/tailscale/state:/var/lib/tailscale
      - /dev/net/tun:/dev/net/tun
    environment:
      - TS_AUTHKEY=${TS_AUTHKEY:-}
      - TS_EXTRA_ARGS=--ssh
      - TS_STATE_DIR=/var/lib/tailscale
EOF

# --- Step 4: Ask for optional auth key ---
read -p "Enter your Tailscale auth key (or press Enter to skip for manual login): " AUTHKEY
if [ -n "$AUTHKEY" ]; then
  export TS_AUTHKEY="$AUTHKEY"
  echo "Using provided Tailscale auth key."
else
  echo "No auth key provided. You will need to authenticate manually later."
fi

# --- Step 5: Start container ---
cd /data/tailscale
echo "Starting Tailscale container..."
sudo docker compose up -d

# --- Step 6: Verification ---
sleep 3
sudo docker ps --filter name=tailscale

echo "=== ✅ Tailscale Docker installation complete ==="
echo ""
echo "Tailscale state stored in: /data/tailscale/state"
echo "To view logs: sudo docker logs tailscale"
echo "To authenticate manually (if no auth key used): sudo docker exec -it tailscale tailscale up"
echo ""
echo "Done!"


