# Detailed Implementation Plan: Develop a Comprehensive Testing Approach using NixOS VM Tests

This document outlines the detailed plan for developing a comprehensive testing approach using NixOS VM tests, tailored for laptop and desktop machines.

## 1. NixOS VM Tests Implementation

Introduction to NixOS VM tests, how they work, and their benefits for testing declarative configurations.

## 2. Writing Basic VM Tests

Setting up a simple VM test and using `testScript` to interact with the VM. Instead of web servers, we will focus on system-level functionalities relevant to laptops and desktops.

### Code Example (Simple NixOS VM test for network connectivity):

```nix
# tests/network-connectivity-test.nix
{ pkgs, lib, ... }:
pkgs.nixosTest {
  name = "network-connectivity-test";
  nodes.machine = { config, pkgs, ... }: {
    # Define a minimal NixOS configuration for the VM
    networking.enable = true;
    networking.hostName = "test-machine";
    # Add basic network configuration if needed for the test
  };
  testScript = ''
    # Wait for the machine to boot and network to be online
    machine.waitForUnit "network-online.target";
    # Test basic internet connectivity
    machine.succeed("ping -c 3 8.8.8.8");
    assert "3 packets transmitted, 3 received" in machine.log;
    # Test DNS resolution
    machine.succeed("dig example.com");
    assert "ANSWER SECTION" in machine.log;
  '';
}
```

## 3. Advanced Testing Scenarios

Testing specific configurations like VPN networks (Tailscale, Wireguard, Nebula), monitoring services (Prometheus), and exploring possibilities for graphical user interface testing.

### Code Example (VM test for Tailscale VPN connectivity):

```nix
# tests/tailscale-vpn-test.nix
{ pkgs, lib, ... }:
pkgs.nixosTest {
  name = "tailscale-vpn-test";
  nodes.client = { config, pkgs, ... }: {
    # Minimal NixOS configuration for a Tailscale client
    services.tailscale.enable = true;
    # For testing, you might use a mock authKey or a pre-generated nodekey
    # config.sops.secrets."tailscale-authkey".path; # Placeholder for sops integration
    # For a real test, you'd need a way to provide a valid auth key or node key
    # For simplicity in a test, you might hardcode a temporary key or use a test-specific mechanism.
    services.tailscale.authKey = "tskey-test-key-for-ci"; # WARNING: Do NOT use real keys in tests
    networking.firewall.allowedTCPPorts = [ 22 ]; # For SSH access within the test
  };
  nodes.server = { config, pkgs, ... }: {
    # A simple server to ping from the client over Tailscale
    services.openssh.enable = true;
    users.users.testuser.isNormalUser = true;
    users.users.testuser.extraGroups = [ "wheel" ];
    users.users.testuser.hashedPassword = ""; # No password for test
    # Ensure Tailscale is enabled on the server as well if it's part of the mesh
    services.tailscale.enable = true;
    services.tailscale.authKey = "tskey-test-key-for-ci-server"; # WARNING: Do NOT use real keys in tests
  };
  testScript = ''
    # Wait for both machines to boot and Tailscale to be up
    client.waitForUnit "tailscale.service";
    server.waitForUnit "tailscale.service";

    # Get Tailscale IP of the server
    serverTailscaleIP=$(server.succeed("tailscale ip -4"));

    # Ping the server from the client over Tailscale
    client.succeed("ping -c 3 $serverTailscaleIP");
    assert "3 packets transmitted, 3 received" in client.log;

    # Test SSH connectivity over Tailscale
    client.succeed("ssh -o StrictHostKeyChecking=no testuser@$serverTailscaleIP 'echo Hello from SSH'");
    assert "Hello from SSH" in client.log;
  '';
}
```

### Code Example (VM test for Prometheus Node Exporter):

```nix
# tests/prometheus-node-exporter-test.nix
{ pkgs, lib, ... }:
pkgs.nixosTest {
  name = "prometheus-node-exporter-test";
  nodes.machine = { config, pkgs, ... }: {
    services.prometheus.exporters.node.enable = true;
    networking.firewall.allowedTCPPorts = [ 9100 ];
  };
  testScript = ''
    machine.waitForUnit "prometheus-node-exporter.service";
    # Check if Node Exporter metrics are accessible
    machine.succeed("curl localhost:9100/metrics");
    assert "node_cpu_seconds_total" in machine.log;
    assert "node_memory_MemTotal_bytes" in machine.log;
  '';
}
```

### Graphical User Interface (GUI) Testing Considerations

While direct GUI interaction in VM tests is complex, we can test the _presence_ and _start-up_ of GUI services or applications. This might involve:

- Checking if display managers (e.g., GDM, LightDM) are active.
- Verifying that Xorg or Wayland sessions start successfully.
- Launching a simple GUI application and checking its process status.
- _Conceptual Example (Testing GUI service startup):_
  ```nix
  # tests/gui-startup-test.nix
  { pkgs, lib, ... }:
  pkgs.nixosTest {
    name = "gui-startup-test";
    nodes.desktop = { config, pkgs, ... }: {
      services.xserver.enable = true;
      services.xserver.displayManager.gdm.enable = true;
      services.xserver.desktopManager.gnome.enable = true;
    };
    testScript = ''
      desktop.waitForUnit "display-manager.service";
      # Check if Xorg/Wayland session is running (conceptual)
      # This would involve checking logs or process lists for relevant entries
      desktop.succeed("loginctl show-session c1 -p Type"); # Check session type (x11/wayland)
      assert "Type=x11" in desktop.log || "Type=wayland" in desktop.log;
      # Attempt to launch a simple GUI app and check its process
      desktop.succeed("su -l testuser -c 'DISPLAY=:0 ${pkgs.xterm}/bin/xterm &'");
      desktop.succeed("pgrep xterm");
      assert "xterm" in desktop.log;
    '';
  }
  ```

## 4. Integrating VM Tests into CI

How to run NixOS VM tests as part of a Github Actions workflow.

### Code Example (Github Actions step for running VM tests):

```yaml
# .github/workflows/test-nixos.yml (part of a larger workflow)
# ...
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      # ... (checkout, nix-installer, magic-nix-cache)
      - name: Run NixOS VM tests
        run: |
          # Run specific tests relevant to the changes
          nix build .#nixosTests.network-connectivity-test
          nix build .#nixosTests.tailscale-vpn-test
          nix build .#nixosTests.prometheus-node-exporter-test
          # Or to run all tests defined in the flake:
          # nix flake check --all-tests
```

## 5. Deployment Validation with Tests

Using VM tests to validate that deployments are successful and services are running as expected on the target machine types (laptops, desktops).

## 6. Test Coverage and Best Practices

Strategies for achieving good test coverage and writing maintainable tests, specifically for system-level and network configurations.
