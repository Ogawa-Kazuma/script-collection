#!/bin/bash
set -e

# === Configuration ===
DATA_DIR="/data/nodered/data"
DOCKER_COMPOSE_FILE="/data/nodered/docker-compose.yml"

# === Prepare directories ===
echo "[1/6] Creating data directory..."
sudo mkdir -p "$DATA_DIR"
sudo chown -R 1000:1000 /data/nodered

# === Create docker-compose.yml ===
echo "[2/6] Creating Docker Compose configuration..."
sudo tee "$DOCKER_COMPOSE_FILE" >/dev/null <<'EOF'
services:
  nodered:
    image: nodered/node-red:latest
    container_name: nodered
    user: "0:0"
    environment: - TZ:Asia/KualaLumpur
    restart: unless-stopped
    network_mode: host
    volumes:
      - /data/nodered/data:/data
EOF

# === Start Node-RED ===
echo "[3/6] Starting Node-RED container..."
sudo docker compose -f "$DOCKER_COMPOSE_FILE" up -d
sleep 10
