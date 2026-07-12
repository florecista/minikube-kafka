#!/usr/bin/env bash

set -euo pipefail

case "$(uname -m)" in
  x86_64)
    architecture="amd64"
    ;;
  aarch64|arm64)
    architecture="arm64"
    ;;
  *)
    echo "Unsupported CPU architecture: $(uname -m)" >&2
    exit 1
    ;;
esac

version="$(curl -fsSL https://dl.k8s.io/release/stable.txt)"
temporary_directory="$(mktemp -d)"
trap 'rm -rf "$temporary_directory"' EXIT

curl -fL \
  "https://dl.k8s.io/release/${version}/bin/linux/${architecture}/kubectl" \
  -o "$temporary_directory/kubectl"
curl -fL \
  "https://dl.k8s.io/release/${version}/bin/linux/${architecture}/kubectl.sha256" \
  -o "$temporary_directory/kubectl.sha256"

(
  cd "$temporary_directory"
  echo "$(cat kubectl.sha256)  kubectl" | sha256sum --check
)

sudo install -o root -g root -m 0755 \
  "$temporary_directory/kubectl" \
  /usr/local/bin/kubectl

kubectl version --client
