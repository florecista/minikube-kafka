#!/usr/bin/env bash

set -euo pipefail

sudo apt-get update

if apt-cache show kcat >/dev/null 2>&1; then
  sudo apt-get install -y kcat
else
  sudo apt-get install -y kafkacat
fi

if command -v kcat >/dev/null 2>&1; then
  kcat -V
else
  kafkacat -V
fi
