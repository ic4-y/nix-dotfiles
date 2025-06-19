{ config, pkgs, ... }:

{
  hardware.graphics = {
    enable = true;
    extraPackages = with pkgs; [
      mesa
      intel-ocl
      intel-compute-runtime
      vaapiIntel
      vaapiVdpau
      libvdpau-va-gl
    ];
  };

  nixpkgs.config.packageOverrides = pkgs: {
    vaapiIntel = pkgs.vaapiIntel.override { enableHybridCodec = true; };
  };

  programs.dconf.enable = true;
  programs.light.enable = true;

  services.xserver = {
    enable = true;
    desktopManager.gnome.enable = true;
    xkb.layout = "us";
  };

  services.xserver.displayManager.gdm.enable = true;
}
