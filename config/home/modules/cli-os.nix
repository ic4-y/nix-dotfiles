{ pkgs, ... }: {
  home.packages = with pkgs; [
    pciutils
    usbutils
    smartmontools
    findutils
    less
    glxinfo
    procps

    unstable.gh

    fzf
    # Use eza as a dropin replacement for exa
    unstable.eza
    zoxide
    ripgrep
    universal-ctags
    du-dust
    duf
    tree-sitter
    jq
    yq

    # file systems and converters
    fuseiso

    gnumake
    gnused
    gawk
    tokei
    socat
    ranger
    ncdu
    xz
    unstable.youtube-dl
    unstable.yt-dlp

    unrar
    unstable.asciinema
    unstable.moc
    unstable.havoc
    unstable.tiny
    unstable.tealdeer

    bottom
    neofetch
    xclip

    # amdgpu monitoring
    unstable.amdgpu_top

    android-file-transfer
  ];

  # bash
  programs.bash = {
    enable = true;
    profileExtra = ''
      export EDITOR=nvim 
      export MOZ_ENABLE_WAYLAND=1
      export MOZ_USE_XINPUT2=1
      export NIXPKGS_ALLOW_UNFREE=1
      export DBX_CONTAINER_MANAGER="docker"
      export DBX_CONTAINER_HOME_PREFIX="''${HOME}/dbx"
      export KUBECONFIG="''${HOME}/.kube/config"

      export OPENRA_DISPLAY_SCALE=2
    '';

    initExtra = ''
      eval "$(direnv hook bash)"
      eval "$(zoxide init bash)"
      eval "$(starship init bash)"

      alias cb='xclip -selection c'
      alias ls='eza -al --color=always --group-directories-first'
      alias cd='z'
      alias lg='lazygit'

      alias gh-login='~/scripts/gh-login.sh'

      alias k='kubectl'
      alias kctx='kubectx'
      alias kns='kubens'

      alias v='nvim'

      alias js='cd ''${HOME}/Coding/javascript'
      alias py='cd ''${HOME}/Coding/python'
      alias rs='cd ''${HOME}/Coding/rust'
      alias cpp='cd ''${HOME}/Coding/cpp'
      alias ans='cd ''${HOME}/Coding/ansible'
      alias ndf='cd ''${HOME}/Coding/nix/nix-dotfiles'

      PATH="$PATH:''${HOME}/.local/bin/"
    '';
  };

  # bat
  programs.bat = {
    enable = true;
  };

  # direnv
  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
    enableNushellIntegration = true;
  };

  # lazygit
  programs.lazygit = {
    enable = true;
    settings = { };
  };

  # zellij
  programs.zellij = {
    enable = true;
  };
}
