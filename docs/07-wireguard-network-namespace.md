# 07-wireguard-network-namespace.md: Wireguard and Systemd Network Namespaces for Application Isolation

This document details the integration of Wireguard with systemd network namespaces for application isolation within NixOS. It covers the setup of Wireguard tunnels, the creation and management of network namespaces, and practical examples of running applications like Brave browser in an isolated environment, all with detailed NixOS configurations.

## 1. Wireguard Implementation Overview

Wireguard is a modern, fast, and secure VPN protocol known for its simplicity and performance. It utilizes public-key cryptography to establish secure tunnels between peers. By leveraging systemd's network namespace capabilities, we can isolate specific applications, ensuring their network traffic is routed exclusively through a Wireguard tunnel, thereby enhancing privacy and security.

### Key Concepts:

- **Wireguard:** A VPN protocol that provides secure, encrypted tunnels. It operates at the network layer and is known for its minimal codebase and high performance.
- **Systemd Network Namespaces:** Linux network namespaces provide an isolated network stack for a process. This includes network interfaces, routing tables, firewall rules, and network access control lists. By running an application within a dedicated network namespace, its network traffic is confined to that namespace.
- **Application Isolation:** The goal is to route an application's network traffic through a Wireguard tunnel that is itself configured within a specific network namespace. This prevents the application from accessing the host's network directly or leaking its traffic outside the intended VPN tunnel.

### How Wireguard and Namespaces Work Together:

1.  A Wireguard interface is configured.
2.  A systemd service creates a new network namespace.
3.  The Wireguard interface is brought up _within_ this new network namespace.
4.  An application is launched, also within the same network namespace, ensuring all its network activity is routed through the Wireguard tunnel.

## 2. NixOS Configuration for Wireguard

This section provides detailed Nix code examples for setting up Wireguard and integrating it with systemd.

### 2.1. NixOS Module for Wireguard Service

We'll define a custom NixOS module to manage Wireguard's configuration declaratively.

```nix
# config/sys/modules/wireguard.nix
{ config, pkgs, lib, ... }:

with lib;

let
  cfg = config.services.wireguard;

  # Helper function to generate a private key file
  mkPrivateKeyFile = { name, content, permissions ? "0400" }: pkgs.writeFile "${name}.key" {
    inherit content;
    mode = permissions;
  };

  # Helper function to generate a Wireguard configuration file
  mkWgConfigFile = { wgConfig }: pkgs.writeText "wg0.conf" (pkgs.writeWireGuardConfig {
    inherit wgConfig;
    # Example wgConfig structure:
    # {
    #   PrivateKey = "YOUR_PRIVATE_KEY";
    #   Address = "10.0.0.2/24";
    #   DNS = "10.0.0.1";
    #   Peer = {
    #     PublicKey = "PEER_PUBLIC_KEY";
    #     AllowedIPs = "0.0.0.0/0";
    #     Endpoint = "YOUR_WIREGUARD_SERVER_IP:51820";
    #   };
    # }
  });

in
{
  options.services.wireguard = {
    enable = mkEnableOption "Wireguard VPN service";

    package = mkPackageOption pkgs "wireguard-tools" { };

    # Configuration for the Wireguard interface
    wgConfig = mkOption {
      type = types.attrsOf types.anything;
      default = {};
      description = "Wireguard configuration options (see Wireguard documentation for details).";
      example = {
        PrivateKey = "YOUR_PRIVATE_KEY_HERE"; # Replace with actual private key
        Address = "10.0.0.2/24"; # IP address for this node within the VPN
        DNS = "10.0.0.1"; # DNS server for the VPN
        Peer = {
          PublicKey = "PEER_PUBLIC_KEY_HERE"; # Public key of the Wireguard server/peer
          AllowedIPs = "0.0.0.0/0"; # Route all traffic through the VPN
          Endpoint = "YOUR_WIREGUARD_SERVER_IP:51820"; # IP and port of the Wireguard server
        };
      };
    };

    # Path for the Wireguard configuration file
    configFile = mkWgConfigFile { wgConfig = cfg.wgConfig; };

  };

  config = mkIf cfg.enable {
    # Ensure wireguard-tools package is installed
    environment.systemPackages = [ cfg.package ];

    # Configure Wireguard interface using systemd-networkd
    # This assumes you are using systemd-networkd for network management.
    # If using NetworkManager, the approach would differ.
    systemd.network = {
      enable = true;
      networks = {
        "wg0.network" = { # Name of the network configuration file
          networkConfig = {
            Description = "Wireguard VPN Tunnel";
            Address = cfg.wgConfig.Address;
            DNS = cfg.wgConfig.DNS;
          };
          wireguard = {
            PrivateKeyFile = "/etc/wireguard/private.key"; # Path to the private key file
            ListenPort = 51820; # Or whatever port you configure
            # Peer configuration is typically handled by wg-quick or similar,
            # but can be managed via systemd-networkd's .netdev and .network files.
            # For simplicity, we'll assume wg-quick or a custom script handles peer setup.
          };
          # If using wg-quick, you'd typically have a .conf file and a systemd service.
          # For a more declarative approach with systemd-networkd:
          # You'd define the interface in .netdev and configure it in .network.
          # Example using wg-quick for simplicity in this doc:
          # services.wg-quick.enable = true;
          # services.wg-quick.interfaces.wg0.config = cfg.configFile;
        };
      };
    };

    # Service to set up the Wireguard interface using wg-quick
    systemd.services.wireguard-wg0 = {
      description = "Wireguard VPN Tunnel (wg0)";
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        Type = "oneshot";
        ExecStart = "${pkgs.wireguard-tools}/bin/wg-quick up wg0";
        ExecStop = "${pkgs.wireguard-tools}/bin/wg-quick down wg0";
        RemainAfterExit = true;
        Environment = "WG_TUNNEL_CONFIG_DIR=/etc/wireguard";
      };
      # Ensure the config file and private key are in place before starting
      path = [ cfg.configFile ];
    };

    # Service to place the private key securely and create the config file
    systemd.services.wireguard-setup = {
      description = "Setup Wireguard Keys and Config";
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        Type = "oneshot";
        ExecStart = ''
          mkdir -p /etc/wireguard
          echo "${cfg.wgConfig.PrivateKey}" > /etc/wireguard/private.key
          chmod 0400 /etc/wireguard/private.key
          echo "${pkgs.writeWireGuardConfig { wgConfig = { PrivateKey = cfg.wgConfig.PrivateKey; Address = cfg.wgConfig.Address; DNS = cfg.wgConfig.DNS; Peer = cfg.wgConfig.Peer; }; }}" > /etc/wireguard/wg0.conf
          chmod 0600 /etc/wireguard/wg0.conf
        '';
        RemainAfterExit = true;
      };
      # Ensure this runs before the wg-quick service
      before = [ "wireguard-wg0.service" ];
    };
  };
}
```

### 2.2. Generating Wireguard Keys

Wireguard uses public-key cryptography. You'll need to generate a private key for your NixOS machine and obtain the public key of the peer (e.g., your Wireguard server or another node).

**Manual Key Generation (can be scripted):**

Use the `wg` command-line tool (part of `wireguard-tools`).

1.  **Generate Private Key:**

    ```bash
    wg genkey > private.key
    ```

2.  **Derive Public Key:**
    ```bash
    wg pubkey < private.key > public.key
    ```

**Integrating Keys into NixOS Configuration:**

You can embed the private key directly into your Nix configuration using `pkgs.writeFile` (as shown in the module above) or manage it more securely using tools like `sops-nix`. For this example, we'll use `pkgs.writeFile` for clarity.

```nix
# Example in configuration.nix for a node
{ config, pkgs, ... }:

{
  services.wireguard = {
    enable = true;
    package = pkgs.wireguard-tools;

    wgConfig = {
      PrivateKey = ''
        # Paste your generated private key here
        YOUR_PRIVATE_KEY_HERE
      '';
      Address = "10.0.0.2/24"; # Example IP for this node
      DNS = "10.0.0.1"; # Example DNS server
      Peer = {
        PublicKey = ''
          # Paste the peer's public key here
          PEER_PUBLIC_KEY_HERE
        '';
        AllowedIPs = "0.0.0.0/0"; # Route all traffic through the VPN
        Endpoint = "YOUR_WIREGUARD_SERVER_IP:51820"; # Replace with actual server IP and port
      };
    };
  };
}
```

## 3. Systemd Network Namespaces and Wireguard Integration

This section details how to create and manage network namespaces and integrate Wireguard within them.

### 3.1. Creating a Network Namespace with Systemd

We can use systemd services to create and manage network namespaces. A common pattern is to use `systemd-nspawn` or `ip netns` commands within a systemd service.

Here's an example of a systemd service that creates a network namespace and brings up a Wireguard interface within it.

```nix
# Example systemd service definition in configuration.nix
{ config, pkgs, ... }:

let
  # Define the Wireguard configuration for the isolated namespace
  isolatedWgConfig = {
    PrivateKey = ''
      # Private key for the Wireguard interface within the namespace
      ISOLATED_PRIVATE_KEY_HERE
    '';
    Address = "10.10.10.2/24"; # IP within the isolated namespace
    DNS = "10.10.10.1"; # DNS for the isolated namespace
    Peer = {
      PublicKey = ''
        # Public key of the peer accessible from the isolated namespace
        ISOLATED_PEER_PUBLIC_KEY_HERE
      '';
      AllowedIPs = "0.0.0.0/0"; # Route all traffic from the namespace through this peer
      Endpoint = "YOUR_WIREGUARD_SERVER_IP:51820"; # Server accessible from the namespace
    };
  };

  # Helper to create the Wireguard config file for the namespace
  isolatedWgConfFile = pkgs.writeText "isolated-wg0.conf" (pkgs.writeWireGuardConfig {
    inherit isolatedWgConfig;
  });

in
{
  # Ensure wireguard-tools is available
  environment.systemPackages = [ pkgs.wireguard-tools ];

  # Service to set up the Wireguard interface within the namespace
  systemd.services.app-wg-setup = {
    description = "Setup Wireguard for isolated application namespace";
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = ''
        # Create the network namespace
        ip netns add appns

        # Create a veth pair to connect the host to the namespace
        ip link add veth0 type veth peer name veth1
        ip link set veth0 up
        ip link set veth1 netns appns
        ip netns exec appns ip link set veth1 up

        # Configure the interface within the namespace
        ip netns exec appns ip addr add 192.168.200.1/24 dev veth1 # Host-side IP for namespace communication

        # Set up Wireguard within the namespace
        ip netns exec appns wg setconf wg0 ${isolatedWgConfFile}
        ip netns exec appns wg syncconf wg0 ${isolatedWgConfFile}
        ip netns exec appns ip link set wg0 up

        # Set default route within the namespace via Wireguard
        ip netns exec appns ip route add default via 10.10.10.1 dev wg0

        # Set DNS within the namespace
        # Ensure /etc/netns/appns exists and is writable by the service
        mkdir -p /etc/netns/appns
        echo "nameserver 10.10.10.1" > /etc/netns/appns/resolv.conf
      '';
      ExecStop = ''
        # Clean up
        ip netns exec appns wg set wg0 down || true
        ip link set veth0 down || true
        ip link delete veth0 || true
        ip netns delete appns || true
      '';
      RemainAfterExit = true;
    };
    # Ensure this runs after network is up and before the application starts
    after = [ "network-online.target" ];
    requires = [ "network-online.target" ];
  };

  # Service to run an application within the namespace
  systemd.services.isolated-brave = {
    description = "Run Brave browser in isolated network namespace";
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "simple";
      ExecStart = "${pkgs.brave}/bin/brave --no-sandbox"; # Example command
      ExecStop = "killall brave || true";
      # Run the command within the 'appns' network namespace
      # Note: The 'ip netns exec appns' prefix needs to be part of the ExecStart command itself.
      # This is a common pattern for running commands in a specific namespace.
      ExecStart = ''
        /usr/bin/ip netns exec appns ${pkgs.brave}/bin/brave --no-sandbox
      '';
      Restart = "on-failure";
    };
    # Ensure Wireguard is set up before starting the application
    requires = [ "app-wg-setup.service" ];
    after = [ "app-wg-setup.service" ];
  };
}
```

### 4. Running Applications in Namespaces (Brave Example)

The NixOS configuration above demonstrates how to set up Wireguard within a network namespace and then run an application (Brave browser in this case) within that same namespace.

- **`app-wg-setup.service`:** This service creates the network namespace (`appns`), sets up a `veth` pair to connect the host to the namespace, configures the Wireguard interface (`wg0`) within the namespace using the provided configuration, and sets the default route and DNS for the namespace.
- **`isolated-brave.service`:** This service launches the Brave browser. Crucially, the `ExecStart` command is prefixed with `/usr/bin/ip netns exec appns`, ensuring Brave runs within the `appns` network namespace.

### 5. Bubblewrap Integration (Optional)

For even stronger isolation, you can combine network namespaces with tools like Bubblewrap (`bwrap`). Bubblewrap provides more granular control over the application's environment, including filesystem access, process capabilities, and network access.

**Conceptual Nix Example for Bubblewrap:**

```nix
# Example snippet for using Bubblewrap within a systemd service
{ config, pkgs, ... }:

let
  # Assuming 'app-wg-setup.service' is already defined and running
  # and 'appns' network namespace is available.
in
{
  systemd.services.isolated-brave-bwrap = {
    description = "Run Brave browser with Bubblewrap in isolated namespace";
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "simple";
      ExecStart = ''
        ${pkgs.bubblewrap}/bin/bwrap --dev-bind / / \
          --proc /proc \
          --dev /dev \
          --tmpfs /tmp \
          --bind /run/user/1000 /run/user/1000 \
          --bind /etc/resolv.conf /etc/resolv.conf \
          --unshare-pid \
          --unshare-ipc \
          --unshare-uts \
          --unshare-mount \
          --share-net \
          --namespace network:appns \
          ${pkgs.brave}/bin/brave --no-sandbox
      '';
      ExecStop = "killall brave || true";
      Restart = "on-failure";
    };
    requires = [ "app-wg-setup.service" ];
    after = [ "app-wg-setup.service" ];
  };
}
```

_Note: The `--share-net` option with `network:appns` tells Bubblewrap to use the specified network namespace. You would need to ensure the namespace is set up correctly beforehand._

### 6. Security Benefits

- **Enhanced Privacy:** All network traffic from the isolated application is forced through the Wireguard tunnel, protecting your online activity and IP address.
- **Reduced Attack Surface:** Isolating applications prevents them from accessing or interfering with the host system's network or other processes.
- **Traffic Leak Prevention:** Ensures that no application traffic bypasses the VPN, maintaining a consistent security posture.
- **Granular Control:** Systemd and Bubblewrap allow for fine-grained control over the application's environment, further hardening its security.

This detailed guide provides the NixOS configurations and conceptual steps to implement Wireguard with systemd network namespaces for robust application isolation.
