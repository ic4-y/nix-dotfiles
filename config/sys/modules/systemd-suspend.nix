{ ... }:
{
  systemd.sleep.extraConfig = ''
    AllowSuspend=yes
    AllowHibernation=no
  '';
}
