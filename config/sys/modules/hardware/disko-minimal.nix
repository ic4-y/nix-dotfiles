{ pkgs, lib, ... }:

{
  disko.devices = {
    disk = {
      vda = {
        # Using vda for the VM test
        type = "disk";
        device = "/dev/vda";
        content = {
          type = "gpt";
          partitions = {
            root = {
              size = "100%";
              content = {
                type = "filesystem";
                format = "ext4";
                mountpoint = "/";
              };
            };
          };
        };
      };
    };
  };
}
