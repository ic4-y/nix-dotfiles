#!/usr/bin/env bash
set -euo pipefail

# Navigate to project root
cd "$(dirname "$0")/.."

# Verify secrets directory exists
if [ ! -d "secrets" ]; then
  echo "Error: 'secrets' directory not found"
  exit 1
fi

# Verify sops is installed
if ! command -v sops &>/dev/null; then
  echo "Error: sops not found. Please install it first."
  exit 1
fi

echo "Decrypting all secrets in secrets/ directory"
find secrets -type f -name '*.enc.yaml' | while read -r file; do
  output="${file%.enc.yaml}.secrets.yaml"
  echo "Decrypting $file → $output"
  sops --decrypt "$file" >"$output" || {
    echo "Error decrypting $file"
    exit 1
  }
done

echo "Decryption complete. Remember to add .secrets.yaml to .gitignore!"
