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
        # Overriding network to true for Discord
        bubblewrap.network = true;
        dbus.policies = {
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
      };
  }).config.env;
}
