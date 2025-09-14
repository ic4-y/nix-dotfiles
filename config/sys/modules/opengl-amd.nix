{ pkgs, ... }:

{
  # hardware.graphics = {
  #   enable = true;
  #   # driSupport = true;
  #   # driSupport32Bit = true;
  #   extraPackages = with pkgs; [
  #     # mesa_drivers
  #     rocmPackages.clr
  #     rocmPackages.rocm-runtime
  #     amdvlk
  #   ];
  #   extraPackages32 = with pkgs; [
  #     driversi686Linux.amdvlk
  #   ];
  # };

  environment.systemPackages = with pkgs.rocmPackages; [
    rocminfo
    rocm-smi
    rocm-runtime
  ];

  hardware.amdgpu = {
    opencl.enable = true;
    amdvlk.enable = true;
    amdvlk.support32Bit.enable = true;
  };

  programs.dconf.enable = true;
  programs.light.enable = true;

  services.xserver = {
    enable = true;
    desktopManager.gnome.enable = true;
    xkb.layout = "us";
    videoDrivers = [ "amdgpu" ];
  };

  services.xserver.displayManager.gdm.enable = true;
}
