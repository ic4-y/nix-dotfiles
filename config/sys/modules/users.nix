{ config, lib, ... }:

{
  users.users.ap = {
    isNormalUser = true;
    extraGroups = [ "wheel" "libvirtd" "vboxusers" "lxd" "docker" "podman" "video" "audio" ];
    initialPassword = "123";
  };

  # Conditionally add the nixops user if openssh is enabled
  users.users.nixops = lib.mkIf config.services.openssh.enable {
    extraGroups = [ "wheel" ];
    isNormalUser = true;
    hashedPassword = "$y$j9T$62Kxh9ONl8JoMvfvcl4pf.$GinFdTwYBAv5v7tbiASvvY3SlHfOx0GEVNkr.zS8xf6";
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIG2FaDBU1OP1xuzlakix+TLZMC1Rc3ZIhVZQlq4gjY3E nix-ed25519"
    ];
  };
}
