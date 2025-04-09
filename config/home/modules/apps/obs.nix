{ pkgs, ... }:

{
  home.packages = with pkgs.unstable; [
    obs-cmd
    obs-cli
  ];

  # programs.obs-studio.enable = true;
  # programs.obs-studio.enableVirtualCamera = true;
  # programs.obs-studio.plugins = with pkgs.unstable; [
  #   obs-studio-plugins.wlrobs
  #   obs-studio-plugins.obs-3d-effect
  # ];
}
