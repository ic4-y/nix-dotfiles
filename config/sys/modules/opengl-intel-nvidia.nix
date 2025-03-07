{ config, pkgs, ... }:

{
  hardware.nvidia.package = config.boot.kernelPackages.nvidiaPackages.stable;
  hardware.nvidia.open = true;

  hardware.graphics = {
    enable = true;
    extraPackages = with pkgs; [
      mesa.drivers
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
    videoDrivers = [ "nvidia" ];
  };

  services.xserver.displayManager.gdm.enable = true;
}
