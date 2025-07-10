{ config, pkgs, ... }:

{
  # Enable the OpenSSH daemon.
  services.openssh.enable = true;

  # Generate host keys if they don't exist.
  services.openssh.hostKeys = [
    {
      type = "ed25519";
      path = "/etc/ssh/ssh_host_ed25519_key";
    }
    {
      type = "rsa";
      path = "/etc/ssh/ssh_host_rsa_key";
      bits = 4096;
    }
  ];

  services.openssh.settings = {
    PasswordAuthentication = false;
    AllowUsers = [ "nixops" ];
    UseDns = false;
    X11Forwarding = false;
  };
}
