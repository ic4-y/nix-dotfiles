{ pkgs, ... }:

{
  fonts = {
    enableDefaultPackages = false;

    packages = with pkgs; [
      material-icons
      material-design-icons
      noto-fonts
      noto-fonts-cjk-sans
      noto-fonts-emoji
      # Replacement for Times New Roman, Arial
      liberation_ttf
      google-fonts

      nerd-fonts.caskaydia-cove
      nerd-fonts.dejavu-sans-mono
      nerd-fonts.fira-code
      nerd-fonts.inconsolata
      nerd-fonts.iosevka
      nerd-fonts.jetbrains-mono
      nerd-fonts.overpass
    ];

    fontconfig.defaultFonts = {
      serif = [ "Noto Serif" "Noto Color Emoji" ];
      sansSerif = [ "Noto Sans" "Noto Color Emoji" ];
      monospace = [ "JetBrainsMono Nerd Font" "Noto Color Emoji" ];
      emoji = [ "Noto Color Emoji" ];
    };
  };

}
