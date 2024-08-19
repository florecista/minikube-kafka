# It's good practice to update system packages
sudo apt update

# In case these are not installed previously let's make sure
sudo apt install -y curl wget apt-transport-https

# Download latest version of Minikube for Linux AMD64
curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64

# Install Minikube
sudo install minikube-linux-amd64 /usr/local/bin/minikube