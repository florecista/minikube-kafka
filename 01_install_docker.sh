#!/usr/bin/env bash

set -euo pipefail

if [[ ${EUID} -eq 0 ]]; then
  echo "Run this script as a normal user. It will request sudo when needed." >&2
  exit 1
fi

if ! command -v sudo >/dev/null 2>&1; then
  echo "sudo is required." >&2
  exit 1
fi

# shellcheck source=/dev/null
. /etc/os-release
if [[ ${ID:-} != "ubuntu" ]]; then
  echo "This installer supports Ubuntu only (detected: ${ID:-unknown})." >&2
  exit 1
fi

conflicting_packages=()
for package in \
  docker.io docker-compose docker-compose-v2 docker-doc \
  podman-docker containerd runc; do
  if dpkg-query -W -f='${db:Status-Abbrev}' "$package" 2>/dev/null | grep -q '^ii'; then
    conflicting_packages+=("$package")
  fi
done

if (( ${#conflicting_packages[@]} > 0 )); then
  sudo apt-get remove -y "${conflicting_packages[@]}"
fi

sudo apt-get update
sudo apt-get install -y ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL \
  https://download.docker.com/linux/ubuntu/gpg \
  -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

sudo tee /etc/apt/sources.list.d/docker.sources >/dev/null <<EOF
Types: deb
URIs: https://download.docker.com/linux/ubuntu
Suites: ${UBUNTU_CODENAME:-$VERSION_CODENAME}
Components: stable
Architectures: $(dpkg --print-architecture)
Signed-By: /etc/apt/keyrings/docker.asc
EOF

sudo apt-get update
sudo apt-get install -y \
  docker-ce \
  docker-ce-cli \
  containerd.io \
  docker-buildx-plugin \
  docker-compose-plugin

sudo systemctl enable --now docker
sudo usermod -aG docker "$USER"
sudo docker run --rm hello-world

echo
echo "Docker is installed. Log out and back in before using Docker without sudo."
