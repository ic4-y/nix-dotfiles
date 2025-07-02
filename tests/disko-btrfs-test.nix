{ pkgs, self, lib, disko, impermanence, ... }:

let
  testLib = import ./testlib.nix { inherit pkgs disko lib; };
in
testLib.makeDiskoTest {
  inherit pkgs disko;
  name = "disko-btrfs-test";
  disko-config = self.nixosModules.disko-test;
  # diskSize = 25 * 1024; # 25 GB
  extraTestScript = ''
    machine.succeed("cryptsetup isLuks /dev/vda2");
    machine.succeed("btrfs subvolume list / | grep -qs 'path root$'");
    machine.succeed("btrfs subvolume list / | grep -qs 'path home$'");
    machine.succeed("btrfs subvolume list / | grep -qs 'path nix$'");
    machine.succeed("btrfs subvolume list / | grep -qs 'path persist$'");
    machine.succeed("btrfs subvolume list / | grep -qs 'path log$'");
    machine.succeed("test -e /swap/swapfile");
  '';
}
