# 07-01. Advanced Application Isolation: Bubblewrap with Wireguard Network Namespaces

This document details an advanced application isolation strategy combining **Bubblewrap** sandboxing with **Wireguard** VPNs running within **systemd network namespaces**. This approach provides the strongest form of network and filesystem isolation for applications, ensuring that their traffic is exclusively routed through a specified VPN tunnel and their access to the host system is severely restricted.

This builds upon the concepts introduced in:

- [`07-wireguard-network-namespace.md`](docs/07-wireguard-network-namespace.md): For setting up Wireguard within systemd network namespaces.
- [`13-bubble-wrap-sandboxing-for-nix-derivations.md`](docs/13-bubble-wrap-sandboxing-for-nix-derivations.md): For declaratively wrapping Nix derivations with Bubblewrap.

## 1. Overview of Combined Isolation

The goal is to run an application such that:

1.  It operates within a **Bubblewrap sandbox**, limiting its filesystem access, process capabilities, and other system resources.
2.  Its entire network stack is confined to a dedicated **Linux network namespace**.
3.  All network traffic from this namespace is forced through a **Wireguard VPN tunnel**, preventing any direct access to the host's default network or traffic leaks.

## 2. Prerequisites

Before implementing this combined isolation, ensure you have:

- A working NixOS or Home-Manager setup.
- `pkgs.bubblewrap` available in your environment.
- Wireguard (`pkgs.wireguard-tools`) configured and ready for use.
- Understanding of network namespaces as described in [`07-wireguard-network-namespace.md`](docs/07-wireguard-network-namespace.md).

## 3. Step-by-Step Implementation

### Step 3.1: Configure Wireguard within a Network Namespace

First, set up a dedicated network namespace and configure your Wireguard interface to operate exclusively within it. This process is detailed in [`07-wireguard-network-namespace.md`](docs/07-wireguard-network-namespace.md), specifically the `app-wg-setup.service` example.

Ensure your `app-wg-setup.service` creates the namespace (e.g., `appns`), sets up the `veth` pair, brings up the Wireguard interface (`wg0`) within `appns`, and configures routing and DNS for that namespace.

**Key components from `07-wireguard-network-namespace.md` to adapt:**

- **`isolatedWgConfig`**: The Wireguard configuration specific to this isolated namespace.
- **`isolatedWgConfFile`**: The generated Wireguard configuration file.
- **`app-wg-setup.service`**: The systemd service responsible for creating the `appns` namespace and configuring Wireguard within it.

### Step 3.2: Modify the Bubblewrap Wrapper to Use the Network Namespace

Now, we will adapt the `mkBwrapWrapper` function (from `lib/bwrap-wrapper.nix`) to accept an optional `networkNamespace` parameter. If provided, the wrapper will execute `bwrap` within that namespace.

**Location**: `lib/bwrap-wrapper.nix` (modify existing file)

```nix
# lib/bwrap-wrapper.nix (modified)
{ pkgs ? import <nixpkgs> {} }:

{
  package,
  executableName,
  bwrap-settings,
  # New optional parameter for network namespace
  networkNamespace ? null,
}:

pkgs.stdenv.mkDerivation {
  name = "${package.name}-sandboxed${if networkNamespace != null then "-netns" else ""}";
  nativeBuildInputs = [ pkgs.makeWrapper ];
  dontUnpack = true;

  bwrapArgs = pkgs.lib.concatStringsSep " " (
    pkgs.lib.mapAttrsToList (name: value:
      if pkgs.lib.isList value then
        pkgs.lib.concatStringsSep " " (map (v: "${name} ${v}") value)
      else if pkgs.lib.isBool value && value then
        name
      else
        "${name} ${value}"
    ) bwrap-settings
  );

  # Conditionally add `ip netns exec` prefix
  execPrefix = pkgs.lib.optionalString (networkNamespace != null)
    "${pkgs.iproute2}/bin/ip netns exec ${networkNamespace}";

  installPhase = ''
    mkdir -p $out/bin
    makeWrapper ${pkgs.bubblewrap}/bin/bwrap $out/bin/${executableName} \
      --prefix PATH : "${pkgs.iproute2}/bin" \
      --add-flags "$bwrapArgs" \
      --add-flags "${package}/bin/${executableName} \"\$@\"" \
      --run "exec $execPrefix ${pkgs.bubblewrap}/bin/bwrap $bwrapArgs ${package}/bin/${executableName} \"\$@\""
    # The above `makeWrapper` line is conceptual. A more robust approach might involve
    # a custom script that handles the `ip netns exec` call.
    # For simplicity and directness in Nix, we'll generate a small shell script.

    # Generate a custom script to handle ip netns exec
    cat > $out/bin/${executableName} << EOF
    #!${pkgs.bash}/bin/bash
    ${pkgs.lib.optionalString (networkNamespace != null) "${pkgs.iproute2}/bin/ip netns exec ${networkNamespace}"} \
    ${pkgs.bubblewrap}/bin/bwrap $bwrapArgs ${package}/bin/${executableName} "\$@"
    EOF
    chmod +x $out/bin/${executableName}
  '';
}
```

**Note on `makeWrapper` vs. custom script**: Directly embedding `ip netns exec` into `makeWrapper`'s `--run` or `--add-flags` can be tricky due to quoting and execution context. A more reliable method, as shown in the modified `installPhase` above, is to generate a small shell script that performs the `ip netns exec` before calling `bwrap`.

### Step 3.3: Define a Sandboxed Application Using the Network Namespace

Now, when defining your sandboxed applications in `packages/sandboxed-apps.nix`, you can specify the network namespace.

**Location**: `packages/sandboxed-apps.nix` (modify existing file)

```nix
# packages/sandboxed-apps.nix (modified)
{ pkgs, ... }:

let
  mkBwrapWrapper = import ../lib/bwrap-wrapper.nix { inherit pkgs; };

  # Define the network namespace name (must match what app-wg-setup.service creates)
  vpnNamespace = "appns"; # Example name from 07-wireguard-network-namespace.md

in
{
  # Example: Sandboxed Firefox using Wireguard VPN in 'appns'
  sandboxed-firefox-vpn = mkBwrapWrapper {
    package = pkgs.firefox;
    executableName = "firefox";
    networkNamespace = vpnNamespace; # Use the defined VPN namespace
    bwrap-settings = {
      "--ro-bind" = [
        "/nix/store" "/nix/store"
        "/etc/resolv.conf" "/etc/resolv.conf"
      ];
      "--dev-bind" = [ "/dev" "/dev" ];
      "--proc" = "/proc";
      "--tmpfs" = "/tmp";
      "--unshare-all" = true;
      "--share-net" = true; # Crucial: tells bwrap to use the existing network namespace
      "--bind" = [
        "~/.mozilla" "~/.mozilla"
        "~/.cache/mozilla" "~/.cache/mozilla"
      ];
    };
  };

  # Example: Sandboxed Discord using Wireguard VPN in 'appns'
  sandboxed-discord-vpn = mkBwrapWrapper {
    package = pkgs.discord;
    executableName = "discord";
    networkNamespace = vpnNamespace; # Use the defined VPN namespace
    bwrap-settings = {
      "--ro-bind" = [
        "/nix/store" "/nix/store"
        "/etc/resolv.conf" "/etc/resolv.conf"
      ];
      "--dev-bind" = [ "/dev" "/dev" ];
      "--proc" = "/proc";
      "--tmpfs" = "/tmp";
      "--unshare-all" = true;
      "--share-net" = true;
      "--bind" = [
        "~/Downloads" "~/Downloads"
        "~/.config/discord" "~/.config/discord"
        "/tmp" "~/" # Block access to the rest of the home directory
      ];
    };
  };
}
```

### Step 3.4: Integrate into System/Home-Manager

Ensure that the `app-wg-setup.service` is enabled and running before any application that uses its network namespace. Then, add the new sandboxed applications to your `home.packages` or `environment.systemPackages`.

```nix
# In your NixOS configuration (e.g., configuration.nix)
{ config, pkgs, ... }:

let
  sandboxed-apps = import ../packages/sandboxed-apps.nix { inherit pkgs; };
in
{
  # Ensure the Wireguard network namespace setup service is enabled
  systemd.services.app-wg-setup.enable = true;

  environment.systemPackages = [
    sandboxed-apps.sandboxed-firefox-vpn
    sandboxed-apps.sandboxed-discord-vpn
  ];

  # Also ensure bubblewrap and iproute2 are available
  environment.systemPackages = [ pkgs.bubblewrap pkgs.iproute2 ];
}
```

## 4. Security Benefits

- **Complete Network Isolation**: Applications cannot access the host's network interfaces directly, only the ones configured within their dedicated namespace (e.g., the Wireguard tunnel).
- **VPN Enforcement**: Guarantees that all network traffic from the sandboxed application is routed through the specified VPN, preventing IP leaks or circumvention.
- **Reduced Attack Surface**: Combines filesystem and process isolation of Bubblewrap with network isolation, creating a highly secure environment for sensitive applications.
- **Declarative Control**: All aspects of the sandbox, network, and VPN are defined in Nix, ensuring reproducibility and easy auditing.

This advanced setup provides a robust solution for critical applications where both system and network isolation are paramount.
