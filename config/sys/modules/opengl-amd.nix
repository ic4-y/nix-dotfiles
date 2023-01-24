{ config, lib, pkgs, ... }:

{
  hardware.opengl = {
    enable = true;
    driSupport = true;
    driSupport32Bit = true;
    extraPackages = with pkgs; [
      mesa_drivers
      rocm-opencl-icd
      rocm-opencl-runtime
    ];
  };

  programs.dconf.enable = true;
  programs.light.enable = true;

  services.xserver = {
    enable = true;
    desktopManager.gnome.enable = true;
    layout = "us";
    videoDrivers = [ "amdgpu" ];
  };

  services.xserver.displayManager.gdm.enable = true;
}