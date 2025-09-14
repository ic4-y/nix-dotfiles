{ pkgs, powerOnBoot, ... }:
{
  hardware.bluetooth = {
    enable = true;
    # disabledPlugins = [ "sap" ];
    # hsphfpd.enable = true;
    package = pkgs.bluez;
    powerOnBoot = powerOnBoot;
  };

  services.blueman.enable = true;
}
