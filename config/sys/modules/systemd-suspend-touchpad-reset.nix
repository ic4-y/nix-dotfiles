{ pkgs, ... }:
{
  # Fix Lenovo Touchpad suspend-resume with improved reliability
  systemd.services.touchpad-reset = {
    description = "Reset touchpad after suspend";
    wantedBy = [ "suspend.target" ];
    after = [ "suspend.target" "systemd-udev-settle.service" ];
    requires = [ "systemd-udev-settle.service" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.bash}/bin/bash -c '${pkgs.kmod}/bin/modprobe -r psmouse || true; sleep 2; ${pkgs.kmod}/bin/modprobe psmouse'";
      ExecStartPost = "${pkgs.util-linux}/bin/logger -t touchpad-reset 'Touchpad reset completed'";
      TimeoutSec = 10;
    };
  };
}
