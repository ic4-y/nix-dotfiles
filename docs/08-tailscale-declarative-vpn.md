# 08-tailscale-declarative-vpn.md: Tailscale Declarative VPN Configuration

This document provides comprehensive documentation on declaratively configuring Tailscale in NixOS, focusing on automated client registration, secure secrets management using `sops-nix`, and the re-integration of existing machines.

## 1. Tailscale Declarative Configuration

### Introduction to Tailscale in NixOS

Tailscale is a zero-configuration VPN that builds on WireGuard, creating a secure mesh network between your devices. It simplifies network access by assigning each device a stable IP address within your private network, regardless of its physical location. In NixOS, Tailscale can be declaratively configured, ensuring consistent and reproducible deployments.

### Basic Declarative Setup

The minimal NixOS configuration to enable Tailscale involves setting `services.tailscale.enable` to `true`. You can also configure `openFirewall` to automatically open necessary ports, or integrate it with existing firewall rules (e.g., those managed by Nebula).

```nix
# config/sys/modules/tailscale.nix (updated)
{
  services.tailscale = {
    enable = true;
    openFirewall = true; # Or integrate with Nebula firewall rules
  };
}
```

## 2. Challenges with Manual Registration

Manual registration using `tailscale up` and `tailscale login` commands is problematic for declarative, automated deployments. In environments like CI/CD pipelines or immutable infrastructure, manual intervention is undesirable and can lead to inconsistencies.

### Ephemeral Nature of Auth Keys

While Tailscale offers `authkey`s for initial registration, these are often short-lived or designed for one-time use. For persistent, automated deployments, a more robust and secure method for client registration is required to avoid manual re-registration after every system rebuild or deployment.

## 3. Secrets Management for Client Keys

`sops-nix` provides a secure and declarative way to manage sensitive information like Tailscale pre-authentication keys (`preAuthKey`) or API keys within your NixOS configuration. This ensures that secrets are encrypted in your version control system and only decrypted on the target machine.

### Generating a Pre-authentication Key in Tailscale

To enable automated client registration, you'll need a reusable pre-authentication key from your Tailscale admin console.

1.  Log in to your Tailscale admin console.
2.  Navigate to the "Auth keys" section.
3.  Generate a new reusable key. Ensure it has the necessary permissions (e.g., "Ephemeral" if you want nodes to automatically remove themselves after a period of inactivity, or "Reusable" for multiple registrations).

### Storing the Key with `sops-nix`

Once you have your pre-authentication key, store it securely using `sops-nix`. This involves creating a plain text secret file, encrypting it, and then referencing the encrypted file in your NixOS configuration.

Refer to the `sops-nix-integration-plan.md` document for the overall secrets management strategy and setup of `sops` and `age` keys.

1.  Create a new file, for example, `secrets/tailscale/authkey.secrets.yaml`, and add your pre-authentication key:
    ```yaml
    # secrets/tailscale/authkey.secrets.yaml
    tailscaleAuthKey: tskey-xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
    ```
2.  Encrypt this file using `sops`. This will create `secrets/tailscale/authkey.enc.yaml`:
    ```bash
    sops --encrypt secrets/tailscale/authkey.secrets.yaml > secrets/tailscale/authkey.enc.yaml
    ```
    The `authkey.enc.yaml` file will contain the encrypted secret and can be safely committed to your Git repository.

### NixOS Configuration to Access the Secret

In your NixOS configuration (e.g., in your host's `configuration.nix` or a dedicated module), use `sops.secrets` to make the `tailscaleAuthKey` available to the Tailscale service.

```nix
# In your host's configuration.nix or a module
{ config, pkgs, lib, ... }:
{
  # Define the sops secret for the Tailscale authentication key
  sops.secrets."tailscale-authkey" = {
    sopsFile = ./secrets/tailscale/authkey.enc.yaml; # Reference the encrypted file
    key = "tailscaleAuthKey"; # The key within the YAML file that holds the secret
    mode = "0400"; # Set appropriate permissions (read-only for root)
    owner = "root";
  };

  # Configure the Tailscale service to use the decrypted authentication key
  services.tailscale = {
    enable = true;
    authKeyFile = config.sops.secrets."tailscale-authkey".path; # Path to the decrypted key file
    # You can add other Tailscale configurations here as needed
  };
}
```

## 4. Automating Client Registration

By setting `services.tailscale.authKeyFile` to the path of your decrypted pre-authentication key, the Tailscale client will automatically register with your Tailscale network during system activation.

### Idempotency

This approach is inherently idempotent. If the machine is already registered with the provided key, Tailscale will recognize its existing identity and will not attempt to re-register unnecessarily. This is crucial for reliable and repeatable deployments.

### Handling Ephemeral Nodes

For ephemeral nodes (e.g., CI/CD runners, temporary VMs), using a reusable pre-authentication key marked as "Ephemeral" in Tailscale's admin console ensures that these nodes automatically de-register after a period of inactivity, keeping your network clean.

### Considerations for `tags` and `nodeAttrs`

You can also declaratively assign tags or other node attributes to your Tailscale clients directly in your NixOS configuration. These tags can then be used for access control policies within your Tailscale network.

```nix
# Example with tags
{
  services.tailscale = {
    enable = true;
    authKeyFile = config.sops.secrets."tailscale-authkey".path;
    extraConfig = {
      tags = [ "server" "nixos" "production" ]; # Assign tags to this node
    };
  };
}
```

## 5. Re-integrating Existing Machines

In scenarios where you are migrating an existing machine to a declarative NixOS configuration, or if a machine's identity needs to be preserved across re-installations, you might want to re-integrate it using its existing node key rather than registering it as a new device.

### Extracting Existing Machine ID/Key

You can retrieve the existing `nodekey` from a running Tailscale instance using the `tailscale status` command. This `nodekey` represents the unique identity of the Tailscale client.

```bash
sudo tailscale status --json | jq -r '.Self.PrivateNodekey'
```

The `jq -r '.Self.PrivateNodekey'` part extracts the private node key from the JSON output. This key is sensitive and should be handled with care.

### NixOS Configuration for Re-integration

To re-integrate an existing machine, you will store its extracted `nodekey` using `sops-nix` and then configure Tailscale to use this `privateKeyFile`. **Note:** When using `privateKeyFile`, you should generally _not_ use `authKeyFile`, as `privateKeyFile` explicitly tells Tailscale to use an existing identity.

1.  Create a new file, for example, `secrets/tailscale/nodekey.secrets.yaml`, and add your extracted private node key:

    ```yaml
    # secrets/tailscale/nodekey.secrets.yaml
    privateNodeKey: nodekey-xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
    ```

2.  Encrypt this file using `sops`. This will create `secrets/tailscale/nodekey.enc.yaml`:
    ```bash
    sops --encrypt secrets/tailscale/nodekey.secrets.yaml > secrets/tailscale/nodekey.enc.yaml
    ```
    The `nodekey.enc.yaml` file will contain the encrypted secret and can be safely committed to your Git repository.

### NixOS Configuration for Re-integration

In your NixOS configuration (e.g., in your host's `configuration.nix` or a dedicated module), use `sops.secrets` to make the `privateNodeKey` available to the Tailscale service.

```nix
# In your host's configuration.nix or a module
{ config, pkgs, lib, ... }:
{
  # Define the sops secret for the Tailscale private node key
  sops.secrets."tailscale-nodekey" = {
    sopsFile = ./secrets/tailscale/nodekey.enc.yaml; # Reference the encrypted file
    key = "privateNodeKey"; # The key within the YAML file that holds the secret
    mode = "0400"; # Set appropriate permissions (read-only for root)
    owner = "root";
  };

  # Configure the Tailscale service to use the decrypted private key
  services.tailscale = {
    enable = true;
    privateKeyFile = config.sops.secrets."tailscale-nodekey".path; # Path to the decrypted key file
    # Ensure you do NOT use authKeyFile when privateKeyFile is set
  };
}
```

### Considerations for `privateKeyFile` vs. `authKeyFile`

It is crucial to understand the distinction between `authKeyFile` and `privateKeyFile`:

- **`authKeyFile`**: Used for initial registration of _new_ devices. The `preAuthKey` is a temporary token that allows a device to join your Tailscale network. Once registered, the device generates its own `nodekey`.
- **`privateKeyFile`**: Used to provide an _existing_ `nodekey` to a Tailscale client. This is for re-integrating a machine that has previously been registered and whose identity you wish to preserve. When `privateKeyFile` is used, `authKeyFile` should generally be omitted, as the client is using a pre-existing identity rather than attempting a new registration.

Using `privateKeyFile` ensures that the machine retains its existing identity on the Tailscale network, including its assigned IP address and any associated tags or ACLs, even after a complete system rebuild or re-deployment. This is particularly useful for servers or long-lived machines where consistent identity is important.

## 6. Conclusion

By leveraging NixOS's declarative nature and `sops-nix` for secure secrets management, Tailscale client configurations can be fully automated and made reproducible. Whether you're registering new ephemeral nodes with pre-authentication keys or re-integrating existing machines with their private node keys, this approach ensures a robust, secure, and hands-off deployment process for your Tailscale VPN.
