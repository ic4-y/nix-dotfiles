{ config, pkgs, ... }:

{
  hardware.nvidia.package = config.boot.kernelPackages.nvidiaPackages.stable;
  hardware.nvidia.open = true;

  services.xserver = {
    videoDrivers = [ "nvidia" ];
  };
}
