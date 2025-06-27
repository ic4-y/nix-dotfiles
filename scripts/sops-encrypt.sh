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

echo "Encrypting all secrets in secrets/ directory"
find secrets -type f -name '*.secrets.yaml' | while read -r file; do
  output="${file%.secrets.yaml}.enc.yaml"
  echo "Encrypting $file → $output"
  # Use the project's .sops.yaml configuration
  # Encrypt to a temporary file first to prevent creating empty files on error
  sops --config .sops.yaml --encrypt "$file" >"${output}.tmp" &&
    mv "${output}.tmp" "$output" || {
    rm -f "${output}.tmp"
    echo "Error encrypting $file"
    exit 1
  }
done

echo "Encryption complete. Remember to commit the .enc.yaml files to version control."
