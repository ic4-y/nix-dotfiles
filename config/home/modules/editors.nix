{ pkgs, ... }:
# let
#   vscode-override = with pkgs; (unstable.vscode.overrideAttrs
#     (oldAttrs: {
#       desktopItem = oldAttrs.desktopItem.override {
#         mimeTypes = [ "text/plain" ];
#       };

#       preFixup =
#         oldAttrs.preFixup
#         + ''
#           gappsWrapperArgs+=(
#             --add-flags "\''${NIXOS_OZONE_WL:+\''${WAYLAND_DISPLAY:+--disable-gpu}}"
#           )
#         '';
#     }));
# in
{
  home.packages = with pkgs; [
    # Coding
    unstable.helix

    #SQL
    unstable.sqlitebrowser
    unstable.beekeeper-studio

    # Cursor
    unstable.code-cursor
  ];

  # Configuration for helix editor
  home.file.".config/helix/config.toml" = {
    executable = false;
    text = ''
      theme = "catppuccin_mocha"

      [editor]
      line-number = "absolute"
      mouse = true
      scrolloff = 2

      [editor.file-picker]
      hidden = false

      [keys.normal]
      g = { a = "code_action" } # Maps `ga` to show possible code actions
      C-c = "no_op"
      "C-/" = "toggle_comments"

      [keys.insert]
      j = { k = "normal_mode" } # Maps `jk` to exit insert mode
      C-c = "normal_mode"

      [keys.select]
    '';
  };

  programs.vscode = {
    enable = true;
    package = pkgs.vscode-fhs;

    extensions = with pkgs; [
      unstable.vscode-extensions.pkief.material-icon-theme
      unstable.vscode-extensions.catppuccin.catppuccin-vsc

      unstable.vscode-extensions.bbenoist.nix
      unstable.vscode-extensions.jnoortheen.nix-ide
      unstable.vscode-extensions.b4dm4n.vscode-nixpkgs-fmt

      unstable.vscode-extensions.haskell.haskell
      unstable.vscode-extensions.astro-build.astro-vscode
      # unstable.vscode-extensions.ms-vscode.cpptools
      unstable.vscode-extensions.ms-python.vscode-pylance
      unstable.vscode-extensions.ms-toolsai.jupyter
      unstable.vscode-extensions.rust-lang.rust-analyzer
      unstable.vscode-extensions.redhat.vscode-yaml
      unstable.vscode-extensions.tamasfe.even-better-toml
    ];

    userSettings = {
      "continue.telemetryEnabled" = false;
      "workbench.iconTheme" = "material-icon-theme";
      "workbench.colorTheme" = "Catppuccin Mocha";
      "editor.fontFamily" = "'JetBrains Mono Nerd Font', monospace";
      "editor.fontLigatures" = true;
      "editor.formatOnSave" = true;
      "extensions.autoUpdate" = false;
      "extensions.autoCheckUpdates" = false;
      "[nix]"."editor.tabSize" = 2;
      "nix.enableLanguageServer" = true;
      "nix.serverPath" = "nixd";
      "python.formatting.provider" = "ruff --format";
      "python.linting.enabled" = true;
      "python.linting.lintOnSave" = true;
      "redhat.telemetry.enabled" = false;
      "telemetry.telemetryLevel" = "off";
      "terminal.integrated.fontFamily" = "'JetBrainsMono Nerd Font'";
      "update.mode" = "none";
      "window.zoomLevel" = 1;
      "window.menuBarVisibility" = "toggle";
    };
  };
}
