{ inputs, system, ... }:
let
  terminalFontFamily = "JetBrainsMono Nerd Font";
  scaleFactor = 1.5;
in
{
  imports = [
    ../home/modules/apps/element-desktop.nix
    (import ../home/modules/apps/alacritty.nix { inherit terminalFontFamily scaleFactor; })
    ../home/modules/apps/atuin.nix
    ../home/modules/apps/carapace.nix
    (import ../home/modules/apps/foot.nix { inherit terminalFontFamily scaleFactor; })
    ../home/modules/apps/nushell.nix
    ../home/modules/apps/lf.nix
    ../home/modules/apps/tmux.nix
    ../home/modules/apps/yazi.nix
    # ../home/modules/apps/davinci-resolve.nix
    ../home/modules/games/dosbox.nix
    ../home/modules/games/games.nix
    ../home/modules/games/openra.nix
    ../home/modules/scripts
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
    (import ../home/modules/xresources.nix { inherit scaleFactor; })
  ];
}
