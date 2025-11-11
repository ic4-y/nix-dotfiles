## Current Task List

- [x] Populate config/sys/modules/nixpak-apps/gui-mixin.nix with common GUI settings.
- [-] Create config/sys/modules/nixpak-apps/discord.nix for the 'discord-sandboxed' package.
- [ ] Integrate 'discord-sandboxed' into the system/Home-Manager configuration.
- [ ] Test 'discord-sandboxed' to ensure it launches and functions correctly.
- [ ] Create config/sys/modules/nixpak-apps/firefox.nix for the 'firefox-sandboxed' package.
- [ ] Integrate 'firefox-sandboxed' into the system/Home-Manager configuration.
- [ ] Test 'firefox-sandboxed' to ensure it launches and functions correctly.

# 13-2. Nixpak Sandboxing Implementation Plan

## 1. Objective

Implement application sandboxing using the `nixpak` library to replace the previous Bubblewrap approach. This plan outlines the steps to sandbox Discord and Firefox with standard sandboxing, without network isolation. To allow coexistence with non-sandboxed versions, the sandboxed applications will be named distinctly (e.g., `discord-sandboxed`).

## 2. Implementation Steps

### Step 2.1: Populate `gui-mixin.nix`

First, we will populate the `config/sys/modules/nixpak-apps/gui-mixin.nix` file with comprehensive common `nixpak` settings required for graphical applications, combining the best practices from the provided examples. This module will be imported by all GUI applications we sandbox.

**Code Example for `config/sys/modules/nixpak-apps/gui-mixin.nix`:**

```nix
# config/sys/modules/nixpak-apps/gui-mixin.nix
{ config, lib, pkgs, sloth, ... }:

{
  config = {
    # Enable D-Bus by default for GUI apps
    dbus.enable = true;

    # Common D-Bus policies for GUI applications
    dbus.policies = {
      "${config.flatpak.appId}" = "own"; # Allow app to own its D-Bus name
      "org.freedesktop.DBus" = "talk";
      "org.gtk.vfs.*" = "talk";
      "org.gtk.vfs" = "talk";
      "ca.desrt.dconf" = "talk";
      "org.freedesktop.portal.*" = "talk"; # XDG Portals for file pickers, etc.
      "org.a11y.Bus" = "talk"; # Accessibility bus
      "org.freedesktop.Notifications" = "talk";
      "org.freedesktop.ScreenSaver" = "talk";
      "org.freedesktop.secrets" = "talk";
      "org.kde.StatusNotifierWatcher" = "talk";
      "org.gnome.SessionManager" = "talk";
      "org.freedesktop.PowerManagement" = "talk";
      "org.gnome.Mutter.IdleMonitor" = "talk";
      "com.canonical.AppMenu.Registrar" = "talk";
      "com.canonical.indicator.application" = "talk";
      "org.ayatana.indicator.application" = "talk";
    };

    # Enable GPU access by default
    gpu.enable = lib.mkDefault true;
    gpu.provider = "nixos"; # Assuming NixOS as the provider

    # Enable fonts and locale
    fonts.enable = true;
    locale.enable = true;

    bubblewrap = {
      # Network access is enabled by default for most GUI apps, but can be overridden
      network = lib.mkDefault true;

      # Sockets for PulseAudio, Wayland, and X11
      sockets = {
        pulse = lib.mkDefault true;
        wayland = lib.mkDefault true;
        x11 = lib.mkDefault true;
      };

      # Read-write bind mounts
      bind.rw = with sloth; [
        # XDG cache/config/state directories, created if they don't exist
        [ (mkdir (concat' appDir "/config")) xdgConfigHome ]
        [ (mkdir appCacheDir) xdgCacheHome ]
        [ (mkdir appDataDir) xdgDataHome ]
        [ (mkdir (concat' appDir "/state")) xdgStateHome ]

        # Portals for file system access
        [ (concat' runtimeDir "/doc/by-app/${config.flatpak.appId}") (concat' runtimeDir "/doc") ]

        # Common cache directories
        (concat' xdgCacheHome "/fontconfig")
        (concat' xdgCacheHome "/mesa_shader_cache")

        # Accessibility and GVFS
        (concat' runtimeDir "/at-spi/bus")
        (concat' runtimeDir "/gvfsd")
      ];

      # Read-only bind mounts
      bind.ro = with sloth; [
        "/etc/fonts"
        "/usr/share/fonts"
        "/usr/share/icons"
        "/usr/share/themes"
        (concat' xdgConfigHome "/gtk-2.0")
        (concat' xdgConfigHome "/gtk-3.0")
        (concat' xdgConfigHome "/gtk-4.0")
        (concat' xdgConfigHome "/fontconfig")
      ];

      # Environment variables for XDG paths and cursor themes
      env = {
        XDG_DATA_DIRS = lib.makeSearchPath "share" [
          pkgs.adwaita-icon-theme
          pkgs.shared-mime-info
        ];
        XCURSOR_PATH = lib.concatStringsSep ":" [
          "${pkgs.adwaita-icon-theme}/share/icons"
          "${pkgs.adwaita-icon-theme}/share/pixmaps"
        ];
      };
    };

    # Enable XDG portal integration for file pickers, etc.
    xdg.portal.enable = true;
    xdg.portal.extraPortals = [ pkgs.xdg-desktop-portal-gtk ]; # or -wlr, etc.
  };
}
```

### Step 2.2: Create Nix Files for Sandboxed Applications

For each application, we will create a Nix file in `config/sys/modules/nixpak-apps/`. These files will contain the `nixpak` configuration for each application and will output distinct package names.

- `config/sys/modules/nixpak-apps/discord.nix` (will output `discord-sandboxed`)
- `config/sys/modules/nixpak-apps/firefox.nix` (will output `firefox-sandboxed`)

### Step 2.3: Implement Standard Sandboxed Discord

Create `config/sys/modules/nixpak-apps/discord.nix`. This will be the first application to be sandboxed. It will use the `gui-mixin.nix` for base settings and will have network access enabled by default. The output package will be named `discord-sandboxed`.

**Code Example for `config/sys/modules/nixpak-apps/discord.nix`:**

```nix
{ config, lib, pkgs, nixpak, ... }:

with lib;

let
  mkNixPak = nixpak.lib.nixpak {
    inherit (pkgs) lib;
    inherit pkgs;
  };

  # Import the gui-mixin for common GUI application settings
  guiMixin = import ./gui-mixin.nix { inherit config lib pkgs sloth; }; # Pass sloth to guiMixin

in
{
  discord-sandboxed = (mkNixPak {
    config =
      { sloth, ... }:
      rec {
        imports = [ guiMixin ]; # Use the gui-mixin
        app.package = pkgs.discord;
        flatpak.appId = "com.discordapp.Discord"; # Standard Flatpak ID for Discord
        # Specific bubblewrap binds for Discord functionality, overriding/extending guiMixin
        bubblewrap.bind.rw = [
          (sloth.concat' sloth.homeDir "/.config/discord") # Persistent config
          (sloth.concat' sloth.homeDir "/.cache/discord") # Cache
          (sloth.concat' sloth.homeDir "/Downloads") # Allow downloads
          "/tmp" # Electron IPC often uses /tmp
        ];
        # D-Bus policies are largely covered by gui-mixin, but can be extended here if needed
      };
  }).config.env;
}
```

### Step 2.4: Test the Standard Sandboxed Discord

After implementing the standard Discord sandbox, we need to integrate it into the system configuration and test it to ensure it launches and functions correctly. This involves adding it to `environment.systemPackages` or `home.packages` and then rebuilding the system.

**Code Example for Integration (e.g., in `configuration.nix` or `home-manager.nix`):**

```nix
# In your NixOS configuration (e.g., configuration.nix) or Home-Manager configuration
{ config, pkgs, ... }:

let
  nixpak-apps = import ../config/sys/modules/nixpak-apps; # Adjust path as necessary
in
{
  environment.systemPackages = [
    nixpak-apps.discord-sandboxed # Add the sandboxed Discord package with its new name
  ];

  # If using Home-Manager:
  # home.packages = [
  #   nixpak-apps.discord-sandboxed
  # ];
}
```

**Testing Steps:**

1.  Rebuild your NixOS system or Home-Manager configuration.
2.  Launch `discord-sandboxed` from your application launcher or terminal.
3.  Verify that Discord starts, connects to the internet, and basic functionalities (e.g., sending messages, voice chat) work as expected.
4.  Check system logs for any `bubblewrap` or `nixpak` related errors.
5.  (Optional) Verify that the original `discord` package (if installed) still functions independently.

### Step 2.5: Implement Standard Sandboxed Firefox

Once the standard Discord sandbox is working, I will proceed with the Firefox implementation:

- `config/sys/modules/nixpak-apps/firefox.nix`

This will import the `gui-mixin.nix` and output the package as `firefox-sandboxed`.

**Code Example for `config/sys/modules/nixpak-apps/firefox.nix`:**

```nix
{ config, lib, pkgs, nixpak, ... }:

with lib;

let
  mkNixPak = nixpak.lib.nixpak {
    inherit (pkgs) lib;
    inherit pkgs;
  };

  guiMixin = import ./gui-mixin.nix { inherit config lib pkgs sloth; }; # Pass sloth to guiMixin

in
{
  firefox-sandboxed = (mkNixPak {
    config =
      { sloth, ... }:
      rec {
        imports = [ guiMixin ];
        app.package = pkgs.firefox;
        flatpak.appId = "org.mozilla.firefox"; # Standard Flatpak ID for Firefox
        bubblewrap.bind.rw = [
          (sloth.concat' sloth.homeDir "/.mozilla") # Firefox profile
          (sloth.concat' sloth.homeDir "/.cache/mozilla") # Firefox cache
          (sloth.concat' sloth.homeDir "/Downloads") # Allow downloads
        ];
        # D-Bus policies for Firefox might be minimal or inherited from gui-mixin
        # Add specific D-Bus policies if Firefox requires them for certain features
      };
  }).config.env;
}
```

### Step 2.6: Final Integration and Testing

Integrate all the new packages into the main NixOS configuration and perform final tests to ensure all application variants work as expected.

**Code Example for Final Integration (e.g., in `configuration.nix` or `home-manager.nix`):**

```nix
# In your NixOS configuration (e.g., configuration.nix) or Home-Manager configuration
{ config, pkgs, ... }:

let
  nixpak-apps = import ../config/sys/modules/nixpak-apps; # Adjust path as necessary
in
{
  environment.systemPackages = [
    nixpak-apps.discord-sandboxed
    nixpak-apps.firefox-sandboxed # Add the sandboxed Firefox package with its new name
  ];

  # If using Home-Manager:
  # home.packages = [
  #   nixpak-apps.discord-sandboxed
  #   nixpak-apps.firefox-sandboxed
  # ];
}
```

**Final Testing Steps:**

1.  Rebuild your NixOS system or Home-Manager configuration.
2.  Launch both `discord-sandboxed` and `firefox-sandboxed`.
3.  Verify that both applications start, connect to the internet, and all core functionalities work correctly within their sandboxes.
4.  Check system logs for any errors.

## 3. Workflow Diagram

```mermaid
graph TD
    A[Start] --> B[Create Implementation Plan docs/13-2-nixpak-sandboxing-plan.md];
    B --> C[Populate gui-mixin.nix];
    C --> D[Implement standard Discord sandbox config/sys/modules/nixpak-apps/discord.nix (discord-sandboxed)];
    D --> E{Test Discord Sandbox};
    E -- Success --> F[Implement standard Firefox sandbox config/sys/modules/nixpak-apps/firefox.nix (firefox-sandboxed)];
    F --> G[Integrate all apps into system];
    G --> H{Final Testing};
    H -- Success --> I[End];
    E -- Failure --> D;
    H -- Failure --> F;
```
