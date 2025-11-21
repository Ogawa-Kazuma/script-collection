#!/bin/bash
set -e   # Exit immediately if a command exits with a non-zero status
set -u   # Treat unset variables as an error

echo "Removing old Docker versions..."
sudo apt-get remove -y docker docker-engine docker.io containerd runc

echo "Updating package lists..."
sudo apt-get update

echo "Installing required dependencies..."
sudo apt-get install -y ca-certificates curl gnupg lsb-release

echo "Adding Docker's official GPG key..."
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

echo "Setting up Docker repository..."
sudo mkdir -p /etc/apt/sources.list.d
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu focal stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

echo "Updating package lists again..."
sudo apt-get update

echo "Installing Docker packages..."
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

echo "Enabling and starting Docker service..."
sudo systemctl enable docker
sudo systemctl start docker

echo "Docker installation complete. Status:"
sudo systemctl status docker --no-pager
