{ inputs, system, ... }:
{
  imports = [
    ../home/modules/apps/element-desktop.nix
    ../home/modules/apps/alacritty.nix
    ../home/modules/cli-os.nix
    ../home/modules/editors.nix
    # ../home/modules/fonts.nix
    ../home/modules/gnome.nix
    ../home/modules/gui.nix
    ../home/modules/home-manager.nix
    ../home/modules/languages.nix
    (import ../home/modules/nvim.nix { inherit inputs system; })
    ../home/modules/wayland.nix
    #../home/modules/xdg.nix
    ../home/modules/xresources.nix
  ];

  xresources.properties = {
    "Xft.dpi" = 96;
  };
}
