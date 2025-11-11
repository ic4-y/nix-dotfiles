{ config, lib, ... }:

with lib;

{
  imports = [
    ./discord.nix
    # ./firefox.nix # Will be added once firefox.nix is created
  ];

  options.sys.modules.nixpak-apps = {
    enable = mkEnableOption "Enable Nixpak sandboxed applications module";
    discord-sandboxed = mkEnableOption "Enable sandboxed Discord";
    firefox-sandboxed = mkEnableOption "Enable sandboxed Firefox";
  };

  config = mkIf config.sys.modules.nixpak-apps.enable {
    environment.systemPackages = mkIf config.sys.modules.nixpak-apps.discord-sandboxed [
      config.nixpak-apps.discord-sandboxed
    ];
    # environment.systemPackages = mkIf config.sys.modules.nixpak-apps.firefox-sandboxed [
    #   config.nixpak-apps.firefox-sandboxed
    # ];
  };
}
