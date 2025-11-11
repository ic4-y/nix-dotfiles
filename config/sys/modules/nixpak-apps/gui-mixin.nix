# config/sys/modules/nixpak-apps/gui-mixin.nix
{ config, lib, pkgs, sloth, ... }:

{
  config = {
    # Enable D-Bus by default for GUI apps
    dbus.enable = true;

    # Minimal common D-Bus policies for GUI applications. App-specific policies will be added in app configs.
    dbus.policies = {
      "${config.flatpak.appId}" = "own"; # Allow app to own its D-Bus name
      "org.freedesktop.DBus" = "talk";
      "org.gtk.vfs.*" = "talk";
      "org.gtk.vfs" = "talk";
      "ca.desrt.dconf" = "talk";
      "org.freedesktop.portal.*" = "talk"; # XDG Portals for file pickers, etc.
      "org.a11y.Bus" = "talk"; # Accessibility bus
    };

    # Enable GPU access by default
    gpu.enable = lib.mkDefault true;
    gpu.provider = "nixos"; # Assuming NixOS as the provider

    # Enable fonts and locale
    fonts.enable = true;
    locale.enable = true;

    bubblewrap = {
      # Network access is disabled by default for sandboxing security purposes.
      # It should be activated on a per-app basis if needed.
      network = lib.mkDefault false;

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
  };
}
