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

temporary_directory="$(mktemp -d)"
trap 'rm -rf "$temporary_directory"' EXIT

curl -fL \
  "https://github.com/kubernetes/minikube/releases/latest/download/minikube-linux-${architecture}" \
  -o "$temporary_directory/minikube"

sudo install -o root -g root -m 0755 \
  "$temporary_directory/minikube" \
  /usr/local/bin/minikube

minikube version
