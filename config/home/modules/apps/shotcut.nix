{ pkgs, ... }:
{
  home.packages = with pkgs.unstable; [
    shotcut
  ];
}
