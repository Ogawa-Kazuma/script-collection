curl -fsSL https://raw.githubusercontent.com.Ogawa-Kazuma/script-collection/refs/heads/main/script-cache-cabin.sh | sh
curl -fsSL https://raw.githubusercontent.com/Ogawa-Kazuma/script-collection/refs/heads/main/install-docker.sh | sed 's/\r$//' | bash
curl -fsSL https://raw.githubusercontent.com/Ogawa-Kazuma/script-collection/refs/heads/main/install-nodered-docker.sh | sed 's/\r$//' | bash
curl https://raw.githubusercontent.com/Ogawa-Kazuma/script-collection/refs/heads/main/install-tailscale-docker.sh | sed 's/\r$//' | bash