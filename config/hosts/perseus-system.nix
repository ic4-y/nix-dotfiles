{
  imports = [
    ../sys/modules/console/console-laptop.nix
    ../sys/modules/hardware/hardware-perseus.nix
    ../sys/modules/kernels/linuxPackages.nix
    # ../sys/modules/kernels/kernel-6.1.nix
    ../sys/modules/adb.nix
    ../sys/modules/bluetooth.nix
    ../sys/modules/boot.nix
    ../sys/modules/firejail.nix
    ../sys/modules/flatpak.nix
    ../sys/modules/fonts.nix
    ../sys/modules/locale.nix
    ../sys/modules/networking-basic.nix
    ../sys/modules/networking-wifi.nix
    ../sys/modules/nix.nix
    ../sys/modules/opengl-intel.nix
    ../sys/modules/pipewire.nix
    ../sys/modules/printing.nix
    ../sys/modules/security.nix
    ../sys/modules/system-packages.nix
    ../sys/modules/systemd-suspend.nix
    ../sys/modules/tablet.nix
    ../sys/modules/tailscale.nix
    ../sys/modules/users.nix
    ../sys/modules/virtualization.nix
    ../sys/modules/xserver-2k.nix
    ../sys/modules/xserver-touchpad.nix
  ];


  hardware.enableAllFirmware = true;

  networking.hostName = "perseus";
  system.stateVersion = "22.05";
}
