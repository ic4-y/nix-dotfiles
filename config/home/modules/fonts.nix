{ pkgs, ... }:

{
  home.packages = with pkgs; [
    nerd-fonts.caskaydia-cove
    nerd-fonts.dejavu-sans-mono
    nerd-fonts.fira-code
    nerd-fonts.inconsolata
    nerd-fonts.iosevka
    nerd-fonts.jetbrains-mono
    nerd-fonts.overpass
  ];
}
