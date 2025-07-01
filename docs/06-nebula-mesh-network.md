# Nebula Mesh Network Implementation

This document details the implementation of a Nebula-based mesh network within the NixOS environment, focusing on declarative configuration, integration with monitoring tools like Prometheus and Grafana, and considerations for CI/CD pipelines.

## 1. Nebula Implementation

Nebula is an open-source overlay networking tool that creates secure, fast, and scalable private networks using public-key cryptography and a custom transport protocol. It establishes a secure mesh network between machines, abstracting away underlying network complexities.

### Core Concepts:

- **Lighthouse:** A crucial node that acts as a rendezvous point for other nodes to discover each other and establish direct connections.
- **Certificates (PKI):** Nebula utilizes a Public Key Infrastructure (PKI) where a Certificate Authority (CA) signs certificates for each node. These certificates contain essential information like IP addresses, ports, and capabilities, ensuring authenticated and authorized communication.
- **Nodes:** Any machine participating in the Nebula network is a node, identified by its unique certificate and listening on a specific UDP port.
- **Firewall:** Nebula includes an integrated firewall that enforces access control policies based on node certificates and IP addresses, controlling traffic flow within the overlay network.

### Why Nebula for this Mesh Network?

Nebula is chosen for its robust security features (end-to-end encryption, certificate-based authentication), ease of management, high performance, and its native support for mesh topologies, enabling direct peer-to-peer communication without relying on a central VPN gateway for all traffic.

## 2. Nebula Node Configuration with NixOS

This section provides detailed Nix code examples for configuring Nebula nodes within NixOS.

### 2.1. NixOS Module for Nebula

We'll define a custom NixOS module to manage Nebula's configuration declaratively.

```nix
# config/sys/modules/nebula.nix
{ config, pkgs, lib, ... }:

with lib;

let
  cfg = config.services.nebula;

  # Helper function to generate a certificate file
  mkCertFile = { name, content, permissions ? "0400" }: pkgs.writeFile "${name}.pem" {
    inherit content;
    mode = permissions;
  };

  # Helper function to generate a Nebula config file
  mkNebulaConfigFile = { configMap }: pkgs.writeText "nebula-config.yaml" (builtins.toJSON configMap);

in
{
  options.services.nebula = {
    enable = mkEnableOption "Nebula overlay network service";

    package = mkPackageOption pkgs "nebula" { };

    # Configuration for the Nebula node
    config = mkOption {
      type = types.attrsOf types.anything;
      default = {};
      description = "Nebula configuration options (see Nebula documentation for details).";
      example = {
        pki = {
          ca = "/etc/nebula/ca.pem"; # Path to CA certificate
          cert = "/etc/nebula/cert.pem"; # Path to node certificate
          key = "/etc/nebula/key.pem"; # Path to node private key
        };
        listen = {
          host = "0.0.0.0";
          port = 4242;
        };
        punchy = true;
        firewall = {
          conntrack = {
            tcp = { timeout = "12h"; };
            udp = { timeout = "1m"; };
          };
          # Define allowed outbound and inbound traffic
          # Example: Allow all outbound, allow inbound from specific certs/IPs
          outbound = [
            { proto = "any"; host = "0.0.0.0/0"; port = "any"; }
          ];
          inbound = [
            # Example: Allow inbound from a specific node certificate (using fingerprint)
            # { proto = "any"; cert = "fingerprint_of_lighthouse"; host = "0.0.0.0/0"; port = "any"; }
            # Example: Allow inbound from any node on a specific port (e.g., Prometheus)
            { proto = "tcp"; host = "0.0.0.0/0"; port = "9090"; } # For Prometheus
            { proto = "tcp"; host = "0.0.0.0/0"; port = "3000"; } # For Grafana
          ];
        };
        lighthouse = {
          am_lighthouse = false; # Set to true if this node is a lighthouse
          hosts = [
            # List of lighthouse host:port addresses
            # "lighthouse_ip_1:4242"
            # "lighthouse_ip_2:4242"
          ];
        };
        # Define static routes if needed
        # static_routes = [
        #   { destination = "192.168.100.0/24"; via = "192.168.100.2"; }
        # ];
      };
    };

    # Paths for certificate files
    pki = {
      caCert = mkCertFile { name = "ca"; content = cfg.config.pki.ca; };
      nodeCert = mkCertFile { name = "cert"; content = cfg.config.pki.cert; };
      nodeKey = mkCertFile { name = "key"; content = cfg.config.pki.key; };
    };

    # Path for the Nebula configuration file
    configFile = mkNebulaConfigFile { configMap = cfg.config; };

  };

  config = mkIf cfg.enable {
    # Ensure Nebula package is installed
    environment.systemPackages = [ cfg.package ];

    # Create directory for Nebula certificates and config
    systemd.services.nebula = {
      description = "Nebula Overlay Network";
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        Type = "simple";
        ExecStart = "${cfg.package}/bin/nebula -config ${cfg.configFile}";
        Restart = "on-failure";
        RestartSec = 5;
        User = "root"; # Nebula typically runs as root to manage network interfaces
        Group = "root";
      };
      # Ensure certificates and config are available before starting
      path = [ cfg.pki.caCert cfg.pki.nodeCert cfg.pki.nodeKey cfg.configFile ];
    };

    # Add Nebula interface to firewall
    networking.firewall.interfaces."nebula0".allowedTCPPorts = [ 9090 3000 ]; # Example ports for Prometheus/Grafana
    networking.firewall.interfaces."nebula0".allowedUDPPorts = [ 4242 ]; # Nebula's default port
  };
}
```

### 2.2. Generating Certificates

Certificates are crucial for Nebula's security. You'll need a CA, and then certificates for each node (including lighthouses).

**Example: Generating Certificates using `nebula-cert` (manual process, can be scripted)**

This is typically done on a separate, secure machine or within a controlled environment.

1.  **Create CA:**

    ```bash
    nebula-cert ca -name "MyOrg"
    ```

    This creates `ca.key` and `ca.crt`.

2.  **Create Lighthouse Certificate:**

    ```bash
    nebula-cert lighthouse -name "lighthouse1" -ip "192.168.100.1/24" -ca-crt ca.crt -ca-key ca.key
    ```

    This creates `lighthouse1.crt` and `lighthouse1.key`.

3.  **Create Node Certificates:**
    ```bash
    nebula-cert node -name "node1" -ip "192.168.100.2/24" -ca-crt ca.crt -ca-key ca.key
    ```
    This creates `node1.crt` and `node1.key`.

**Integrating Certificates into NixOS Configuration:**

You would typically copy these generated certificate files to a secure location on your NixOS machine (e.g., `/etc/nebula/`) and then reference them in your `services.nebula.config`.

```nix
# Example in configuration.nix for a node
{ config, pkgs, ... }:

{
  services.nebula = {
    enable = true;
    package = pkgs.nebula; # Ensure nebula is installed

    config = {
      pki = {
        ca = pkgs.writeFile {
          name = "nebula-ca.pem";
          destination = "/etc/nebula/ca.pem";
          text = ''
            # Content of ca.crt
            -----BEGIN NEBULA CERTIFICATE-----
            ...
            -----END NEBULA CERTIFICATE-----
          '';
          mode = "0400"; # Read-only for root
        };
        cert = pkgs.writeFile {
          name = "node1-cert.pem";
          destination = "/etc/nebula/cert.pem";
          text = ''
            # Content of node1.crt
            -----BEGIN NEBULA CERTIFICATE-----
            ...
            -----END NEBULA CERTIFICATE-----
          '';
          mode = "0400";
        };
        key = pkgs.writeFile {
          name = "node1-key.pem";
          destination = "/etc/nebula/key.pem";
          text = ''
            # Content of node1.key
            -----BEGIN NEBULA PRIVATE KEY-----
            ...
            -----END NEBULA PRIVATE KEY-----
          '';
          mode = "0400";
        };
      };

      listen = {
        host = "0.0.0.0";
        port = 4242;
      };

      firewall = {
        conntrack = {
          tcp = { timeout = "12h"; };
          udp = { timeout = "1m"; };
        };
        outbound = [
          { proto = "any"; host = "0.0.0.0/0"; port = "any"; }
        ];
        inbound = [
          # Allow Prometheus and Grafana traffic from any node in the mesh
          { proto = "tcp"; host = "0.0.0.0/0"; port = "9090"; } # Prometheus
          { proto = "tcp"; host = "0.0.0.0/0"; port = "3000"; } # Grafana
        ];
      };

      lighthouse = {
        am_lighthouse = false; # This node is not a lighthouse
        hosts = [
          "192.168.100.1:4242" # IP of the lighthouse node
        ];
      };
    };
  };
}
```

### 2.3. Lighthouse Configuration

To configure a node as a lighthouse, set `am_lighthouse = true` in its Nebula configuration.

```nix
# Example for a Lighthouse node in configuration.nix
{ config, pkgs, ... }:

{
  services.nebula = {
    enable = true;
    package = pkgs.nebula;

    config = {
      pki = {
        # ... (CA, cert, key paths for the lighthouse node) ...
      };

      listen = {
        host = "0.0.0.0";
        port = 4242;
      };

      # Lighthouse nodes typically have broader firewall rules to allow connections
      firewall = {
        conntrack = {
          tcp = { timeout = "12h"; };
          udp = { timeout = "1m"; };
        };
        outbound = [
          { proto = "any"; host = "0.0.0.0/0"; port = "any"; }
        ];
        inbound = [
          # Allow all inbound traffic on the Nebula port from any node
          { proto = "udp"; host = "0.0.0.0/0"; port = "4242"; }
          # Allow specific TCP ports if needed for other services on the lighthouse
          { proto = "tcp"; host = "0.0.0.0/0"; port = "9090"; } # Prometheus
          { proto = "tcp"; host = "0.0.0.0/0"; port = "3000"; } # Grafana
        ];
      };

      lighthouse = {
        am_lighthouse = true; # This node IS a lighthouse
        # No 'hosts' needed for a lighthouse itself, as it's the discovery point
      };
    };
  };
}
```

## 3. Mesh Network Setup and Integration

### 3.1. Prometheus and Grafana Integration

To allow Grafana to aggregate data from Prometheus through the Nebula network, ensure:

1.  **Prometheus Server Configuration:** The Prometheus server (running on one of the nodes) is configured to scrape metrics from Node Exporters on other nodes. The `scrapeConfigs` in Prometheus's NixOS configuration should use the Nebula IP addresses of the target nodes.

    ```nix
    # Example for Prometheus server configuration in configuration.nix
    services.prometheus = {
      enable = true;
      port = 9090;
      scrapeConfigs = [
        {
          job_name = "nixos_nodes";
          static_configs = [
            {
              targets = [
                "192.168.100.2:9100" # Nebula IP of node1
                "192.168.100.3:9100" # Nebula IP of node2
              ];
            }
          ];
        }
      ];
    };
    ```

2.  **Grafana Configuration:** Grafana is configured with Prometheus as a data source, using the Nebula IP address of the Prometheus server.

    ```nix
    # Example for Grafana configuration in configuration.nix
    services.grafana = {
      enable = true;
      port = 3000;
      settings = {
        datasources = {
          "Prometheus" = {
            type = "prometheus";
            url = "http://192.168.100.1:9090"; # Nebula IP of Prometheus server
            isDefault = true;
          };
        };
      };
    };
    ```

3.  **Nebula Firewall Rules:** Ensure that the Nebula firewall rules on both the Prometheus server and the client nodes allow TCP traffic on ports 9090 (Prometheus) and 3000 (Grafana) between the relevant Nebula IPs. The examples in section 2.2 and 2.3 cover this.

### 3.2. CI/CD Integration

Nebula can provide secure access for CI/CD runners to your machines.

- **Runner as a Nebula Node:** Configure your CI/CD runners (e.g., GitHub Actions self-hosted runners, GitLab CI runners) as Nebula nodes. This involves generating a specific certificate for the runner and configuring it to connect to your Nebula network.
- **Access Control:** Use Nebula's firewall rules and certificate attributes to grant specific access permissions to CI/CD runners, allowing them to deploy applications, run tests, or access services on your machines securely. For example, a runner might only be allowed to SSH into specific machines or access deployment directories.

## 4. Security Best Practices

- **Certificate Management:** Securely store your CA private key. Implement a process for generating and distributing node certificates, including rotation policies. Consider using tools like `sops` for managing secrets like private keys within your Nix configuration.
- **Least Privilege Firewall:** Configure Nebula's firewall rules to allow only necessary traffic between nodes. Restrict access to specific ports and protocols based on the function of each node.
- **Monitoring:** Monitor Nebula's logs for any unusual activity, connection attempts, or firewall rejections. Integrate these logs with your central logging system.
- **NixOS Security:** Leverage NixOS's declarative security features, such as `services.auditd` for system auditing and robust firewall management, in conjunction with Nebula's network-level security.

This detailed plan provides a foundation for implementing Nebula with NixOS, emphasizing declarative configuration and integration with your monitoring and CI/CD workflows.
