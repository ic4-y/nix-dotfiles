{
  home = {
    username = "ap";
    homeDirectory = "/home/ap";
    stateVersion = "23.05";
  };

  nixpkgs.config = {
    allowUnfree = true;
  };
  # nixpkgs.overlays = [ overlay-unstable overlay-custom ];

  programs.home-manager.enable = true;

  home.sessionVariables = {
    EDITOR = "nvim";
  };
}
