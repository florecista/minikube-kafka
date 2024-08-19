# It's good practice to update system packages
sudo apt update
sudo apt install apt-transport-https curl

# Install Docker
sudo apt install docker.io

# Install Docker service
sudo systemctl enable docker
sudo systemctl start docker

# Create docker group
sudo groupadd docker

# Add user to docker group
sudo usermod -aG docker $USER && newgrp docker

# Change permissions for docker.sock !! This is very important
sudo chmod 666 /var/run/docker.sock

# Restart docker
sudo systemctl restart docker