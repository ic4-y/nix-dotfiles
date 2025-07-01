# SOPS-Nix Integration Plan

## Objective

Implement secure secret management for NixOS configurations using sops-nix, with encrypted files (`.enc.yaml`) committed to git and decrypted files (`.secrets.yaml`) kept locally.

## Key Principles

1.  **Encrypted files (`.enc.yaml`)**: Committed to version control.
2.  **Decrypted files (`.secrets.yaml`)**: Never committed, kept locally only.
3.  **sopsFile references**: Always point to encrypted files in Nix configurations.

## Prerequisites

Ensure the following tools are installed and accessible in your environment:

- **sops**: For encrypting and decrypting secrets.
- **age**: The underlying encryption tool used by sops.

## Repository Structure

```
secrets/
├── common/               # Shared across all machines
│   ├── wireless.enc.yaml # Encrypted wireless credentials
│   ├── vpn.enc.yaml      # Encrypted VPN credentials
│   └── services.enc.yaml # Encrypted common service tokens
├── archon/               # Host-specific secrets
│   ├── wireless.enc.yaml
│   └── system.enc.yaml
├── cadmus/
│   ├── wireless.enc.yaml
│   └── system.enc.yaml
└── perseus/
    ├── wireless.enc.yaml
    └── system.enc.yaml
```

## Implementation Steps

### 1. Generate and Manage Age Keys

- **Master Key**: Generate a master age key for general encryption/decryption. Store the private key securely (e.g., in a password manager or encrypted USB).
  ```bash
  age-keygen -o ~/.config/sops/age/keys.txt
  # Copy the public key (starts with age1) for .sops.yaml
  ```
- **Machine-Specific Keys**: For each machine (archon, cadmus, perseus), generate a unique age key pair. Store the private key on the respective machine (e.g., `/var/lib/sops/age/key.txt`) and add its public key to `.sops.yaml`.
  ```bash
  # On each machine (e.g., archon)
  sudo age-keygen -o /var/lib/sops/age/key.txt
  sudo chmod 600 /var/lib/sops/age/key.txt
  # Copy the public key for .sops.yaml
  ```

### 2. Update `.sops.yaml`

Configure SOPS to use your age keys and define creation rules for encrypted files. This configuration ensures that both the original `.secrets.yaml` files (when encrypting) and the `.enc.yaml` files (when decrypting) are handled correctly by SOPS.

```yaml
creation_rules:
  # Rule for decrypted files during encryption (when you run sops --encrypt on .secrets.yaml)
  - path_regex: \.secrets\.yaml$
    key_groups:
      - age:
          # Common keys (e.g., master key, shared machine keys)
          - age1a46d4397rqy3mzeejsku7282t90ydwq9vuxxap84hy9d4yge2u7srx0gtx # Example common key 1
          - age1jv7506mvark8m938egs6e38zzax4srt6u4vj90tycgxnf77mkurqmu95ae # Example common key 2
      - age:
          # Machine-specific keys (e.g., for archon, cadmus, perseus)
          - <ARCHON_PUBLIC_KEY>
          - <CADMUS_PUBLIC_KEY>
          - <PERSEUS_PUBLIC_KEY>

  # Rule for encrypted files during decryption (when you run sops --decrypt on .enc.yaml)
  - path_regex: \.enc\.yaml$
    key_groups:
      - age:
          # Common keys (e.g., master key, shared machine keys)
          - age1a46d4397rqy3mzeejsku7282t90ydwq9vuxxap84hy9d4yge2u7srx0gtx # Example common key 1
          - age1jv7506mvark8m938egs6e38zzax4srt6u4vj90tycgxnf77mkurqmu95ae # Example common key 2
      - age:
          # Machine-specific keys (e.g., for archon, cadmus, perseus)
          - <ARCHON_PUBLIC_KEY>
          - <CADMUS_PUBLIC_KEY>
          - <PERSEUS_PUBLIC_KEY>
```

### 3. Configure `.gitignore`

Add entries to your `.gitignore` file to prevent decrypted secret files from being committed.

```
# SOPS secrets
*.secrets.yaml
```

### 4. Add `sops-nix` to `flake.nix`

Integrate `sops-nix` into your Nix flake and pass it to your NixOS configurations.

```nix
{
  inputs = {
    nixpkgs.url = "nixpkgs/nixos-25.05";

    sops-nix.url = "github:Mic92/sops-nix";
    sops-nix.inputs.nixpkgs.follows = "nixpkgs";
    # Add other inputs as needed
  };

  outputs = { self, nixpkgs, sops-nix, ... }@inputs: {
    nixosConfigurations = {
      archon = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux"; # Specify system
        specialArgs = { inherit inputs; }; # Pass inputs to modules
        modules = [
          sops-nix.nixosModules.sops
          ./config/hosts/archon-system.nix
          # Other system-wide modules
        ];
      };
      cadmus = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = { inherit inputs; };
        modules = [
          sops-nix.nixosModules.sops
          ./config/hosts/cadmus-system.nix
        ];
      };
      perseus = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = { inherit inputs; };
        modules = [
          sops-nix.nixosModules.sops
          ./config/hosts/perseus-system.nix
        ];
      };
    };
  };
}
```

### 5. Secret Usage in Nix Configs (point to encrypted files)

Reference encrypted files in your NixOS configurations. Also, configure `sops.age.keyFile` for each machine to enable decryption.

**Example: `config/hosts/archon-system.nix`**

```nix
{ config, pkgs, lib, ... }:

{
  # Configure sops to use the machine-specific age key
  sops.age.keyFile = "/var/lib/sops/age/key.txt";

  # Example: Decrypting a YAML file containing multiple secrets (e.g., wireless credentials)
  sops.secrets."wireless-raw" = {
    sopsFile = ./secrets/common/wireless.enc.yaml; # Reference encrypted file
    format = "yaml"; # Specify format if the secret is a structured file (e.g., YAML, JSON)
    mode = "0400";
    owner = "root";
  };

  # Example: Extracting environment variables from the decrypted YAML
  # This creates a file at /run/secrets/wireless.env with contents like KEY=VALUE
  sops.secrets."wireless-env" = {
    key = "wireless.env"; # Key within the YAML that contains environment variables
    sopsFile = config.sops.secrets."wireless-raw".path;
    format = "binary"; # Use binary format for direct file content
    path = "/run/secrets/wireless.env"; # Path where the environment file will be created
    mode = "0400";
    owner = "root";
  };

  # Usage in network configuration (e.g., for NetworkManager profiles)
  # This points NetworkManager to the file containing the decrypted environment variables.
  networking.networkmanager.ensureProfiles.environmentFiles = [ config.sops.secrets."wireless-env".path ];

  # Note: For simple single-value secrets, a direct sops.secrets."my-secret" = { sopsFile = ...; } is sufficient.
  # The above example demonstrates extracting multiple environment variables from a single encrypted YAML file,
  # aligning with the pattern used in `config/sys/modules/network-wifi-networks.nix`.

  # Example for a host-specific secret
  sops.secrets."archon/system-secret" = {
    sopsFile = ./secrets/archon/system.enc.yaml;
    mode = "0400";
    owner = "root";
  };
  # ... other configurations
}
```

### 6. Script Automation

Create scripts for encrypting and decrypting secrets.

**`scripts/sops-encrypt.sh`** (local use only):

```bash
#!/usr/bin/env bash
set -euo pipefail # Exit on error, unset variables, pipefail

echo "Encrypting .secrets.yaml files to .enc.yaml..."
find secrets -type f -name '*.secrets.yaml' | while read -r file; do
  output="${file%.secrets.yaml}.enc.yaml"
  echo "Encrypting $file -> $output"
  if sops --encrypt "$file" > "$output"; then
    echo "Successfully encrypted $file"
  else
    echo "Error: Failed to encrypt $file" >&2
    exit 1
  fi
done
echo "Encryption process complete."
```

**`scripts/sops-decrypt.sh`** (local use only):

```bash
#!/usr/bin/env bash
set -euo pipefail # Exit on error, unset variables, pipefail

echo "Decrypting .enc.yaml files to .secrets.yaml..."
find secrets -type f -name '*.enc.yaml' | while read -r file; do
  output="${file%.enc.yaml}.secrets.yaml"
  echo "Decrypting $file -> $output"
  if sops --decrypt "$file" > "$output"; then
    echo "Successfully decrypted $file"
  else
    echo "Error: Failed to decrypt $file" >&2
    exit 1
  fi
done
echo "Decryption process complete."
```

### 7. Initial Secret Creation Workflow

To create a new secret:

1.  Create a new file with the `.secrets.yaml` extension (e.g., `secrets/common/new-service.secrets.yaml`).
2.  Add your secret content to this file.
3.  Run `scripts/sops-encrypt.sh` to create the encrypted `.enc.yaml` file.
4.  Add the `.enc.yaml` file to git and commit.

## Workflow

```mermaid
graph TD
    A[Generate Age Keys] --> B[Configure .sops.yaml]
    B --> C[Add .gitignore entries]
    C --> D[Add sops-nix to flake.nix]
    D --> E[Create .secrets.yaml (initial)]
    E --> F[Run sops-encrypt.sh]
    F --> G[Commit .enc.yaml to git]
    G --> H[Pull changes on another machine]
    H --> I[Ensure machine-specific age key is present]
    I --> J[Run sops-decrypt.sh]
    J --> K[Use decrypted secrets in NixOS]
    K --> L[Deploy NixOS configuration]
    L --> M[Validate service functionality]

    subgraph Ongoing Secret Management
        N[Edit existing .secrets.yaml] --> F
        F --> G
    end
```

## Verification

1.  **Confirm `sopsFile` points to encrypted files**:
    ```bash
    grep -r 'sopsFile' config/hosts/
    # Should show paths ending with .enc.yaml
    ```
2.  **Verify `.gitignore`**:
    ```bash
    git check-ignore -v secrets/common/wireless.secrets.yaml
    # Should indicate the file is ignored
    ```
3.  **Test secret decryption on each machine**:
    ```bash
    sops --decrypt secrets/common/wireless.enc.yaml
    # Should output the decrypted content
    ```
4.  **Validate service functionality after deployment**: Ensure services relying on secrets (e.g., wireless, VPN) function correctly after a NixOS rebuild.

## Security Practices

- **Gitignore**: Ensure `.secrets.yaml` files are in `.gitignore`.
- **Key Management**: Store age private keys securely. Never commit private keys to version control. Consider using a hardware security module (HSM) or a secure key management service for master keys.
- **Access Control**: Limit who has access to decrypt secrets (i.e., who has access to the private age keys).
- **Auditing**: Regularly review decryption access logs if your key management system supports it.
- **Principle of Least Privilege**: Only grant access to secrets on machines that strictly require them.

## Rollback Strategy

In case of issues during or after implementation:

1.  Revert relevant commits in your git repository.
2.  Ensure all `.secrets.yaml` files are removed or restored to their previous state.
3.  Rebuild your NixOS configuration to revert to the previous state.
