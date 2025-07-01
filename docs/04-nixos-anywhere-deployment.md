# Detailed Deployment Strategy with NixOS Anywhere

This document outlines a comprehensive and idempotent deployment strategy for NixOS to new machines using NixOS Anywhere. It covers secure SSH host key management, automated deployment, and validation, ensuring the process can be run multiple times without adverse effects.

## NixOS Anywhere Implementation

NixOS Anywhere is a powerful tool for remotely installing and deploying NixOS configurations. It streamlines the process of provisioning new systems or updating existing ones from a central control machine.

### Key Features:

- **Remote Provisioning:** Install NixOS on bare metal, virtual machines, or cloud instances over SSH.
- **Declarative Configuration:** Applies your NixOS flake configuration directly to the target.
- **Secure Communication:** Integrates with SSH for secure remote operations.
- **File Transfer:** Allows transferring extra files to the target during deployment.

## Comprehensive Deployment Strategy

The deployment strategy is broken down into three main phases:

1.  **Prepare Environment:** Load necessary variables and ensure project context.
2.  **Secure Host Key Management:** Upload pre-determined SSH host keys to the target and validate them against a secure source (e.g., `sops`). This ensures trust in the remote host's identity.
3.  **Execute NixOS Anywhere:** Run the deployment with the specified flake and transferred host keys.

### Prerequisites:

- **`.env` file:** Contains `REMOTE_HOST` (hostname or IP) and `REMOTE_IP` (IP address) variables.
- **`sops`:** Used for decrypting sensitive information like SSH host keys.
- **SSH access:** The deployment machine must have SSH access to the target host, typically via a temporary key or password for initial setup.
- **NixOS Flake:** Your NixOS configuration defined as a flake.
- **Encrypted SSH Host Keys:** Public and private SSH host keys for the target machine, encrypted with `sops` (e.g., `secrets/ssh_host_ed25519_key.enc.yaml`, `secrets/ssh_host_ed25519_public_key.enc.yaml`).
- **`.sops.yaml`:** Configured to include the age key associated with the host key for validation.

### 1. Prepare Environment

This step ensures that all necessary environment variables are loaded from a `.env` file. This makes the script flexible and avoids hardcoding sensitive information.

```bash
# Load variables from .env file
if [ -f .env ]; then
  set -o allexport
  source .env
  set +o allexport
else
  echo "--- .env file not found. Please create one with the required variables."
  exit 1
fi

# Navigate to project root (assuming script is run from a subdirectory)
cd "$(dirname "$0")/.." # Adjust this path if your script is not in a subdirectory
```

### 2. Secure Host Key Management

This phase ensures that the target machine's SSH host key is securely managed. It involves uploading a pre-generated host key and then validating that the host's key matches the expected key stored securely in your repository. This makes the deployment idempotent regarding host keys, as it will re-upload and re-validate if needed.

#### 2.1. Uploading SSH Host Key to Target

This script decrypts the SSH host key from `sops`-encrypted files and securely copies them to the target machine's `/etc/ssh/` directory. It then sets appropriate permissions and restarts the SSH daemon on the remote host. Finally, it removes any old entries for the remote host from the local `known_hosts` file to prevent conflicts.

```bash
#!/usr/bin/env bash

# (Include .env loading and cd to project root from step 1)

echo "--- Uploading SSH host key to $REMOTE_HOST"

# Decrypt and extract the SSH keys from the sops-encrypted file
# Ensure these paths are correct relative to your project root
SSH_HOST_KEY=$(sops --decrypt --extract '["ssh_host_ed25519_key"]' "./secrets/ssh_host_ed25519_key.enc.yaml")
SSH_HOST_PUB_KEY=$(sops --decrypt --extract '["ssh_host_ed25519_public_key"]' "./secrets/ssh_host_ed25519_public_key.enc.yaml")

# Create a temporary directory for the extracted keys
TEMP_DIR=$(mktemp -d)
echo "$SSH_HOST_KEY" >"$TEMP_DIR/ssh_host_ed25519_key"
echo "$SSH_HOST_PUB_KEY" >"$TEMP_DIR/ssh_host_ed25519_key.pub"

# Secure permissions for the private key
chmod 600 "$TEMP_DIR/ssh_host_ed25519_key"

# Copy the keys to the remote host and set permissions
# Assumes SSH access is already configured (e.g., via ssh-agent or password)
scp "$TEMP_DIR/ssh_host_ed25519_key" "$TEMP_DIR/ssh_host_ed25519_key.pub" "$REMOTE_HOST:/etc/ssh/"
ssh "$REMOTE_HOST" "chmod 600 /etc/ssh/ssh_host_ed25519_key && chmod 644 /etc/ssh/ssh_host_ed25519_key.pub && systemctl restart sshd"

# Remove the old hostkey from the local known_hosts file to avoid warnings/errors
ssh-keygen -R "$REMOTE_IP"

# Clean up temporary files
rm -rf "$TEMP_DIR"
```

#### 2.2. Validating SSH Host Key

This script validates that the SSH host key presented by the remote machine matches the expected age key stored in your `.sops.yaml` file. This provides an additional layer of security by verifying the authenticity of the target host.

```bash
#!/usr/bin/env bash

# (Include .env loading and cd to project root from step 1)

echo "--- Validating the SSH host key on $REMOTE_IP"

# Extract the age key associated with #hostkey from .sops.yaml
# This assumes your .sops.yaml has a comment like '# hostkey' above the age key
echo "--- Extracting the SSH key from .sops.yaml"
AGE_KEY_EXPECTED=$(awk '/# hostkey/{getline; print}' .sops.yaml | tr -d ' ' | sed 's/^-//')

# Use ssh-keyscan to get the remote host's ed25519 key
echo "--- Using ssh-keyscan on $REMOTE_IP"
REMOTE_SSH_KEY=$(ssh-keyscan -t ed25519 "$REMOTE_IP" 2>/dev/null | grep 'ssh-ed25519' | awk '{print $2 " " $3}')

# Convert the SSH host key to the age key format
echo "--- Passing key to ssh-to-age"
AGE_KEY_ACTUAL=$(echo "$REMOTE_SSH_KEY" | ssh-to-age)

# Compare the extracted age key with the expected one
echo "--- Comparing keys"
echo "--- expected key: $AGE_KEY_EXPECTED"
echo "--- actual key: $AGE_KEY_ACTUAL"

if [ "$AGE_KEY_ACTUAL" == "$AGE_KEY_EXPECTED" ]; then
  echo "Validation successful: The SSH host key matches the age key in .sops.yaml."
else
  echo "Validation failed: The SSH host key does not match the age key in .sops.yaml."
  exit 1 # Exit if validation fails for security reasons
fi
```

### 3. Execute NixOS Anywhere

This step performs the actual NixOS deployment using `nixos-anywhere`. It also handles securely passing the decrypted SSH host key to `nixos-anywhere` using the `--extra-files` option, ensuring the host key is present on the target during installation.

```bash
#!/usr/bin/env bash

# (Include .env loading and cd to project root from step 1)

echo "--- Calling nixos-anywhere for deployment"

# Prepare the SSH host key to upload using --extra-files
# This creates a temporary directory structure that mirrors the target's /etc/ssh
TEMP_ROOT=$(mktemp -d)
install -d -m755 "$TEMP_ROOT/etc/ssh"
sops --decrypt --extract '["ssh_host_ed25519_key"]' "./secrets/ssh_host_ed25519_key.enc.yaml" >"$TEMP_ROOT/etc/ssh/ssh_host_ed25519_key"
chmod 600 "$TEMP_ROOT/etc/ssh/ssh_host_ed25519_key"

# Execute nixos-anywhere
# --flake: Points to your NixOS flake and the specific host configuration
# --target-host: The remote host to deploy to
# -i: Path to your SSH private key for connecting to the target
# --extra-files: Transfers the temporary directory containing the host key to the target
nix run github:nix-community/nixos-anywhere -- \
    --flake ".#${REMOTE_HOST}" \
    --target-host "$REMOTE_HOST" \
    -i "/home/ap/.ssh/nix-ed25519" \
    --extra-files "$TEMP_ROOT" \
    --build-on-remote # Build the system closure on the remote host

# Clean up the temporary directory
rm -rf "$TEMP_ROOT"
```

## Idempotent Deployment Workflow

To create a single, idempotent script, combine the above phases into a sequential workflow. Each step is designed to be re-runnable without causing issues if the state already exists.

```bash
#!/usr/bin/env bash

set -euo pipefail # Exit on error, unset variables, or failed pipe commands

# --- 1. Prepare Environment ---
# Load variables from .env file
if [ -f .env ]; then
  set -o allexport
  source .env
  set +o allexport
else
  echo "--- .env file not found. Please create one with the required variables."
  exit 1
fi

# Navigate to project root (adjust if your script is not in a subdirectory)
cd "$(dirname "$0")/.."

echo "--- Starting idempotent NixOS Anywhere deployment for ${REMOTE_HOST} ---"

# --- 2. Secure Host Key Management ---

# 2.1. Uploading SSH Host Key to Target
echo "--- Uploading SSH host key to $REMOTE_HOST"
SSH_HOST_KEY=$(sops --decrypt --extract '["ssh_host_ed25519_key"]' "./secrets/ssh_host_ed25519_key.enc.yaml")
SSH_HOST_PUB_KEY=$(sops --decrypt --extract '["ssh_host_ed25519_public_key"]' "./secrets/ssh_host_ed25519_public_key.enc.yaml")

TEMP_DIR=$(mktemp -d)
echo "$SSH_HOST_KEY" >"$TEMP_DIR/ssh_host_ed25519_key"
echo "$SSH_HOST_PUB_KEY" >"$TEMP_DIR/ssh_host_ed25519_key.pub"
chmod 600 "$TEMP_DIR/ssh_host_ed25519_key"

# Use sshpass if password-based authentication is needed for initial scp/ssh
# For true idempotency, ensure SSH keys are set up for passwordless access after first run
# Example with sshpass (install it first):
# sshpass -p "$REMOTE_PASSWORD" scp "$TEMP_DIR/ssh_host_ed25519_key" "$TEMP_DIR/ssh_host_ed25519_key.pub" "$SSH_USER@$REMOTE_HOST:/etc/ssh/"
# sshpass -p "$REMOTE_PASSWORD" ssh "$SSH_USER@$REMOTE_HOST" "chmod 600 /etc/ssh/ssh_host_ed25519_key && chmod 644 /etc/ssh/ssh_host_ed25519_key.pub && systemctl restart sshd"

# Assuming SSH key-based authentication is set up for subsequent runs
scp "$TEMP_DIR/ssh_host_ed25519_key" "$TEMP_DIR/ssh_host_ed25519_key.pub" "$REMOTE_HOST:/etc/ssh/"
ssh "$REMOTE_HOST" "chmod 600 /etc/ssh/ssh_host_ed25519_key && chmod 644 /etc/ssh/ssh_host_ed25519_key.pub && systemctl restart sshd"

ssh-keygen -R "$REMOTE_IP" # Remove old entry from known_hosts
rm -rf "$TEMP_DIR"

# 2.2. Validating SSH Host Key
echo "--- Validating the SSH host key on $REMOTE_IP"
AGE_KEY_EXPECTED=$(awk '/# hostkey/{getline; print}' .sops.yaml | tr -d ' ' | sed 's/^-//')
REMOTE_SSH_KEY=$(ssh-keyscan -t ed25519 "$REMOTE_IP" 2>/dev/null | grep 'ssh-ed25519' | awk '{print $2 " " $3}')
AGE_KEY_ACTUAL=$(echo "$REMOTE_SSH_KEY" | ssh-to-age)

echo "--- expected key: $AGE_KEY_EXPECTED"
echo "--- actual key: $AGE_KEY_ACTUAL"

if [ "$AGE_KEY_ACTUAL" == "$AGE_KEY_EXPECTED" ]; then
  echo "Validation successful: The SSH host key matches the age key in .sops.yaml."
else
  echo "Validation failed: The SSH host key does not match the age key in .sops.yaml."
  exit 1
fi

# --- 3. Execute NixOS Anywhere ---
echo "--- Calling nixos-anywhere for deployment"
TEMP_ROOT=$(mktemp -d)
install -d -m755 "$TEMP_ROOT/etc/ssh"
sops --decrypt --extract '["ssh_host_ed25519_key"]' "./secrets/ssh_host_ed25519_key.enc.yaml" >"$TEMP_ROOT/etc/ssh/ssh_host_ed25519_key"
chmod 600 "$TEMP_ROOT/etc/ssh/ssh_host_ed25519_key"

nix run github:nix-community/nixos-anywhere -- \
    --flake ".#${REMOTE_HOST}" \
    --target-host "$REMOTE_HOST" \
    -i "/home/ap/.ssh/nix-ed25519" \
    --extra-files "$TEMP_ROOT" \
    --build-on-remote

rm -rf "$TEMP_ROOT"

echo "--- NixOS Anywhere deployment completed successfully for ${REMOTE_HOST} ---"
```

### Idempotency Considerations:

- **Host Key Upload:** The `scp` command will overwrite existing files, making the host key upload idempotent. Restarting `sshd` is also idempotent.
- **`ssh-keygen -R`:** This command removes existing entries, so re-running it is safe.
- **NixOS Anywhere:** `nixos-anywhere` itself is designed to be idempotent. If the target system already matches the flake configuration, it will perform minimal or no changes. The `--build-on-remote` flag ensures that the build process is also idempotent on the remote side.
- **Temporary Directories:** The use of `mktemp -d` and `rm -rf` ensures that temporary files are created and cleaned up properly on each run.

This comprehensive script provides a robust and repeatable method for deploying NixOS configurations to new or existing machines.
