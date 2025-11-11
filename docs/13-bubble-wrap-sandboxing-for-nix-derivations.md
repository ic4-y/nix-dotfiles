# 13. Declarative Sandboxing with Bubblewrap for Nix Derivations

This document outlines a detailed, Nix-native approach to sandboxing applications using Bubblewrap. The focus is on creating declarative wrappers for existing Nix derivations, ensuring that sandboxing policies are reproducible and managed entirely within your NixOS or Home-Manager configuration.

## 1. Core Concept: Wrapping Nix Derivations

Instead of relying on mutable shell scripts, we will create a new Nix derivation that "wraps" an existing application package. This wrapper derivation will produce an executable script that launches the original application inside a Bubblewrap sandbox with a specific, declaratively defined policy.

This approach offers several advantages:

- **Declarative & Reproducible**: The entire sandbox configuration is version-controlled and part of your Nix configuration.
- **Seamless Integration**: The wrapped application can be installed just like any other package and will appear in the user's `PATH`.
- **Isolation**: The wrapper is self-contained and does not depend on external, mutable scripts.

## 2. Implementation Plan

### Step 2.1: Create a Reusable Bubblewrap Wrapper Function

We will create a reusable Nix function that takes an application package and a sandbox configuration as inputs and returns a wrapped derivation. This promotes modularity and avoids repetitive code.

**Location**: `packages/bwrap-wrapper.nix` (new file)

```nix
# packages/bwrap-wrapper.nix
{ pkgs ? import <nixpkgs> {} }:

{
  # The package to be wrapped (e.g., pkgs.firefox)
  package,
  # The executable name within the package's /bin directory
  executableName,
  # Attribute set defining the bwrap sandbox policy
  bwrap-settings,
}:

pkgs.stdenv.mkDerivation {
  name = "${package.name}-sandboxed";
  nativeBuildInputs = [ pkgs.makeWrapper ];
  dontUnpack = true;

  # Construct the bwrap arguments from the settings attribute set
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

  installPhase = ''
    mkdir -p $out/bin
    makeWrapper ${pkgs.bubblewrap}/bin/bwrap $out/bin/${executableName} \
      --add-flags "$bwrapArgs" \
      --add-flags "${package}/bin/${executableName} \"\$@\""
  '';
}
```

### Step 2.2: Define Sandbox Policies and Wrap Applications

Next, we will use this function to wrap specific applications. We can do this in a central file or directly where the packages are defined.

**Location**: `packages/sandboxed-apps.nix` (new file)

```nix
# packages/sandboxed-apps.nix
{ pkgs, ... }:

let
  # Import the reusable wrapper function
  mkBwrapWrapper = import ./bwrap-wrapper.nix { inherit pkgs; };

in
{
  # Example: Sandboxed Firefox
  sandboxed-firefox = mkBwrapWrapper {
    package = pkgs.firefox;
    executableName = "firefox";
    bwrap-settings = {
      "--ro-bind" = [ "/nix/store" "/nix/store" ];
      "--dev-bind" = [ "/dev" "/dev" ];
      "--proc" = "/proc";
      "--tmpfs" = "/tmp";
      "--unshare-all" = true;
      "--share-net" = true; # Allow network access
      "--bind" = [
        "~/.mozilla" "~/.mozilla"
        "~/.cache/mozilla" "~/.cache/mozilla"
      ];
      "--ro-bind" = [
        "/etc/resolv.conf" "/etc/resolv.conf"
      ];
    };
  };

  # Example: Sandboxed Discord with more restrictive permissions
  sandboxed-discord = mkBwrapWrapper {
    package = pkgs.discord;
    executableName = "discord";
    bwrap-settings = {
      "--ro-bind" = [ "/nix/store" "/nix/store" ];
      "--dev-bind" = [ "/dev" "/dev" ];
      "--proc" = "/proc";
      "--tmpfs" = "/tmp";
      "--unshare-all" = true;
      "--share-net" = true;
      "--bind" = [
        "~/Downloads" "~/Downloads"
        "~/.config/discord" "~/.config/discord"
      ];
      "--ro-bind" = [
        "/etc/resolv.conf" "/etc/resolv.conf"
      ];
      # Block access to the rest of the home directory
      "--bind" = [ "/tmp" "~/" ];
    };
  };
}
```

### Step 2.3: Integrate Sandboxed Packages into the System

Finally, integrate the newly created sandboxed packages into your system or Home-Manager configuration.

#### For Home-Manager:

You can add the sandboxed packages to `home.packages`.

```nix
# In your home-manager configuration (e.g., config/home/home-manager.nix)
{ pkgs, ... }:

let
  sandboxed-apps = import ../../packages/sandboxed-apps.nix { inherit pkgs; };
in
{
  home.packages = [
    sandboxed-apps.sandboxed-firefox
    sandboxed-apps.sandboxed-discord
    # other packages...
  ];

  # To ensure the sandboxed version is used, you might need to
  # remove the original package if it was installed elsewhere.
}
```

#### For System-wide NixOS Configuration:

You can add the packages to `environment.systemPackages`.

```nix
# In your NixOS configuration (e.g., configuration.nix)
{ pkgs, ... }:

let
  sandboxed-apps = import ../packages/sandboxed-apps.nix { inherit pkgs; };
in
{
  environment.systemPackages = [
    sandboxed-apps.sandboxed-firefox
    # other packages...
  ];
}
```

## 3. Advanced Topics

### Combining with Network Namespaces

For applications requiring strict network isolation (e.g., routing through a specific VPN), you can combine this approach with the systemd network namespace techniques outlined in `07-wireguard-network-namespace.md`.

The wrapper would be modified to execute the `bwrap` command within a specific network namespace using `ip netns exec <namespace>`.

### Filesystem Permissions and `xdg-desktop-portal`

For sandboxed GUI applications to function correctly (e.g., for file pickers), ensure that `xdg-desktop-portal` and its relevant backends (like `xdg-desktop-portal-gtk` or `xdg-desktop-portal-wlr`) are enabled in your system configuration. Bubblewrap will use these portals to safely grant temporary access to files outside the sandbox.

```nix
# In your NixOS or Home-Manager configuration
{
  xdg.portal = {
    enable = true;
    extraPortals = [ pkgs.xdg-desktop-portal-gtk ]; # or -wlr, etc.
  };
}
```

This declarative, derivation-based approach provides a powerful and maintainable way to enforce application sandboxing across your NixOS systems.
