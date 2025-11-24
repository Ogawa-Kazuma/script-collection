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
sudo nano /etc/systemd/system/nodered.service

[Unit]
Description=NodeRED (root using admin's Node 20)
After=network.target

[Service]
Type=simple

User=root
Group=root

Environment="PATH=/root/.nvm/versions/node/v20.19.5/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

ExecStart=/root/.nvm/versions/node/v20.19.5/bin/node-red

WorkingDirectory=/root

Restart=on-failure

[Install]
WantedBy=multi-user.target



sudo systemctl daemon-reload
sudo systemctl enable node-red
sudo systemctl start node-red
sudo systemctl status node-red


