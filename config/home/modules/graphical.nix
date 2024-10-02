{ pkgs, ... }: {
  home.packages = with pkgs; [
    unstable.gimp
    unstable.inkscape
  ];
}
