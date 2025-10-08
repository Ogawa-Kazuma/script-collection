sudo apt install -y --fix-missing curl
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.6/install.sh | bash
source ~/.bashrc
nvm install 20
nvm use 20
nvm alias default 20
npm install -g --unsafe-perm node-red
sudo mkdir -p /etc/udev/rules.d
echo 'KERNEL=="ttyUSB[0-9]*", MODE="0666"' | sudo tee /etc/udev/rules.d/99-serial.rules
sudo udevadm control --reload-rules
sudo udevadm trigger
sudo nano /etc/systemd/system/node-red.service

[Unit]
Description=Node-RED
After=network.target

[Service]
ExecStart=/home/admin/.nvm/versions/node/v20.19.5/bin/node-red
WorkingDirectory=/home/admin
User=admin
Group=admin
Environment=NODE_ENV=production
Restart=on-failure
# Optional: prevent environment problems with NVM
Environment=PATH=/home/admin/.nvm/versions/node/v20.19.5/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

[Install]
WantedBy=multi-user.target


sudo systemctl daemon-reload
sudo systemctl enable node-red
sudo systemctl start node-red
sudo systemctl status node-red
