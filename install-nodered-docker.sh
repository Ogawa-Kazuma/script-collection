#!/bin/bash

set -e

# === Configuration ===
DATA_DIR="/data/nodered/data"
DOCKER_COMPOSE_FILE="/data/nodered/docker-compose.yml"
FLOW_URL="https://raw.githubusercontent.com/USERNAME/REPO/BRANCH/path/to/flow.json"  # <-- CHANGE THIS

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
    restart: unless-stopped
    network_mode: host
    volumes:
      - /data/nodered/data:/data
EOF

# === Start Node-RED ===
echo "[3/6] Starting Node-RED container..."
sudo docker compose -f "$DOCKER_COMPOSE_FILE" up -d
sleep 10

# === Enable file-based context storage ===
echo "[4/6] Enabling file-based context storage..."
sudo sed -i '/^ *contextStorage:/,/},/d' "$DATA_DIR/settings.js" || true
sudo sed -i '/^ *functionGlobalContext:/i\    contextStorage: {\n        default: {\n            module: "localfilesystem"\n        }\n    },' "$DATA_DIR/settings.js" || true
sudo chown -R 1000:1000 "$DATA_DIR"

# === Install custom nodes ===
echo "[5/6] Installing custom Node-RED nodes..."
sudo docker exec -u 0 nodered bash -c '
cd /data
cat <<JSON > package.json
{
  "name": "node-red-project",
  "version": "0.0.1",
  "private": true,
  "dependencies": {
    "node-red-contrib-queue-gate": "~1.5.5",
    "node-red-node-ping": "~0.3.3",
    "node-red-node-serialport": "~2.0.3"
  }
}
JSON
npm install --omit=dev --no-fund --no-audit
'

# === Import flow from GitHub ===
echo "[6/6] Importing flow from GitHub..."
sudo docker exec -u 0 nodered bash -c "
curl -fsSL '$FLOW_URL' -o /data/flows.json &&
chown 1000:1000 /data/flows.json
"

# === Restart Node-RED ===
sudo docker restart nodered
echo "✅ Node-RED installed and configured successfully!"
echo "🌐 Access it at: http://localhost:1880"



