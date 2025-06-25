{ config, lib, pkgs, modulesPath, ... }:

{
  imports =
    [
      (modulesPath + "/installer/scan/not-detected.nix")
    ];

  boot.initrd.availableKernelModules = [ "xhci_pci" "ahci" "nvme" "usb_storage" "sd_mod" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-intel" ];
  boot.kernelParams = [
    "intel_iommu=on"
    "psmouse.synaptics_intertouch=1"
    "psmouse.elantech_smbus=0"
    # "psmouse.rate=200"
    # "psmouse.resolution=3200"
    # try fixing touchpad suspend-resume issues
    "i8042.reset"
    "i8042.nomux"
    "i8042.nopnp"
    "i8042.noloop"
  ];
  boot.extraModulePackages = [ ];

  fileSystems."/" =
    {
      device = "/dev/disk/by-uuid/bb3927d6-ca2b-42b4-b9f4-689445b1a084";
      fsType = "btrfs";
      options = [ "subvol=root" "compress=zstd" "noatime" ];
    };

  boot.initrd.luks.devices."nixenc".device = "/dev/disk/by-uuid/af7c2808-6537-4a5a-9067-53a01a8c4b13";

  fileSystems."/home" =
    {
      device = "/dev/disk/by-uuid/bb3927d6-ca2b-42b4-b9f4-689445b1a084";
      fsType = "btrfs";
      options = [ "subvol=home" "compress=zstd" "noatime" ];
    };

  fileSystems."/nix" =
    {
      device = "/dev/disk/by-uuid/bb3927d6-ca2b-42b4-b9f4-689445b1a084";
      fsType = "btrfs";
      options = [ "subvol=nix" "compress=zstd" "noatime" ];
    };

  fileSystems."/var/log" =
    {
      device = "/dev/disk/by-uuid/bb3927d6-ca2b-42b4-b9f4-689445b1a084";
      fsType = "btrfs";
      options = [ "subvol=log" "compress=zstd" "noatime" ];
    };

  fileSystems."/swap" =
    {
      device = "/dev/disk/by-uuid/bb3927d6-ca2b-42b4-b9f4-689445b1a084";
      fsType = "btrfs";
      options = [ "subvol=swap" "compress=zstd" "noatime" ];
    };

  fileSystems."/boot" =
    {
      device = "/dev/disk/by-uuid/0522-EE87";
      fsType = "vfat";
    };

  swapDevices = [{
    device = "/swap/swapfile";
    size = 8192;
  }];

  networking.useDHCP = lib.mkDefault true;

  powerManagement.cpuFreqGovernor = lib.mkDefault "powersave";
  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}
