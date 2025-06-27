#!/usr/bin/env bash
# Extract age public key from machine's SSH host key
set -euo pipefail

if [ ! -f "/etc/ssh/ssh_host_ed25519_key.pub" ]; then
  echo "Error: SSH host key not found at /etc/ssh/ssh_host_ed25519_key.pub"
  exit 1
fi

ssh-to-age </etc/ssh/ssh_host_ed25519_key.pub
