{ inputs, system, ... }:
{
  imports = [
    ../home/modules/apps/element-desktop.nix
    ../home/modules/apps/alacritty.nix
    # ../home/modules/apps/lf.nix
    # ../home/modules/apps/davinci-resolve.nix
    ../home/modules/games/dosbox.nix
    ../home/modules/games/games.nix
    ../home/modules/games/openmw.nix
    ../home/modules/games/openra.nix
    ../home/modules/cli-os.nix
    ../home/modules/editors.nix
    ../home/modules/graphical.nix
    ../home/modules/gnome.nix
    ../home/modules/gui.nix
    ../home/modules/home-manager.nix
    ../home/modules/languages.nix
    (import ../home/modules/nvim.nix { inherit inputs system; })
    ../home/modules/wine.nix
    #../home/modules/xdg.nix
    ../home/modules/xresources.nix
  ];

  xresources.properties = {
    "Xft.dpi" = 144;
  };
}
