#!/bin/bash
set -e

# === Variables ===
DATA_DIR="/data/restreamer"
COMPOSE_FILE="$DATA_DIR/docker-compose.yml"

# === Step 1: Ensure Docker is installed ===
if ! command -v docker &>/dev/null; then
  echo "[INFO] Installing Docker..."
  sudo apt update -y
  sudo apt install -y ca-certificates curl gnupg lsb-release
  sudo mkdir -p /etc/apt/keyrings
  curl -fsSL https://download.docker.com/linux/$(. /etc/os-release; echo "$ID")/gpg | \
    sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
  echo \
    "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
    https://download.docker.com/linux/$(. /etc/os-release; echo "$ID") \
    $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list >/dev/null
  sudo apt update -y
  sudo apt install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
  sudo systemctl enable docker
  sudo systemctl start docker
fi

# === Step 2: Prepare directories ===
echo "[INFO] Creating Restreamer directories..."
sudo mkdir -p "$DATA_DIR/data" "$DATA_DIR/db"
sudo chown -R 1000:1000 "$DATA_DIR"

# === Step 3: Create docker-compose.yml ===
echo "[INFO] Creating docker-compose.yml..."
cat <<EOF | sudo tee "$COMPOSE_FILE" >/dev/null
services:
  restreamer:
    image: datarhei/restreamer:latest
    container_name: restreamer
    restart: unless-stopped
    ports:
      - "8080:8080"   # Web UI
      - "1935:1935"   # RTMP input
    environment:
      - RS_USERNAME=admin
      - RS_PASSWORD=changeme
      - RS_TOKEN=restreamer
      # === Auto Input Configuration ===
      - RS_INPUT_TYPE=rtsp
      - RS_INPUT_URL=rtsp://admin:password@192.168.1.11:554/live/ch00_0
      - RS_INPUT_AUDIO=false
      - RS_INPUT_RECONNECT=true
      # Optional: set output to internal HLS (for browser playback)
      - RS_OUTPUT_TYPE=hls
      - RS_OUTPUT_HLS=true
    volumes:
      - /data/restreamer/data:/restreamer/db
      - /data/restreamer/db:/restreamer/recordings
    network_mode: bridge
EOF

# === Step 4: Start Restreamer ===
echo "[INFO] Starting Restreamer with Docker Compose..."
sudo docker compose -f "$COMPOSE_FILE" up -d

echo "✅ Restreamer setup complete!"
echo "Access it at: http://<your-device-ip>:8080"
echo "Login with username: admin, password: changeme"

