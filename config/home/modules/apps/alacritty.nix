{ pkgs, scaleFactor, terminalFontFamily, ... }:
let
  wrapped-alacritty = with pkgs; (writeShellScriptBin "alacritty" ''
    if pgrep ".gnome-shell" > /dev/null; then env WAYLAND_DISPLAY= ${pkgs.alacritty}/bin/alacritty; else ${pkgs.alacritty}/bin/alacritty; fi
  '');
  baseFontSize = 11; # Base font size
  computedFontSize = baseFontSize * scaleFactor;
in
{
  home.packages = with pkgs; [
    # Wrap alacritty in script
    (symlinkJoin {
      name = "alacritty";
      paths = [
        wrapped-alacritty
        pkgs.alacritty
      ];
    })
  ];

  # alacritty config
  home.file.".config/alacritty/alacritty.toml" = {
    executable = false;
    text = ''
      import = [
        # uncomment the flavour you want below:
        # "~/.config/alacritty/catppuccin-latte.toml"
        # "~/.config/alacritty/catppuccin-frappe.toml"
        # "~/.config/alacritty/catppuccin-macchiato.toml"
         "~/.config/alacritty/catppuccin-mocha.toml"
      ]

      [font]
      # size = 11
      size = ${toString computedFontSize}

      [font.bold]
      family = "${terminalFontFamily}"
      style = "Bold"

      [font.normal]
      family = "${terminalFontFamily}"
      style = "Regular"

      [window.padding]
      x = 15
      y = 15
    '';
  };

  # alacritty colorschemes
  home.file.".config/alacritty/catppuccin-frappe.toml" = {
    executable = false;
    text = ''
      [colors.primary]
      background = "#303446"
      foreground = "#c6d0f5"
      dim_foreground = "#838ba7"
      bright_foreground = "#c6d0f5"

      [colors.cursor]
      text = "#303446"
      cursor = "#f2d5cf"

      [colors.vi_mode_cursor]
      text = "#303446"
      cursor = "#babbf1"

      [colors.search.matches]
      foreground = "#303446"
      background = "#a5adce"

      [colors.search.focused_match]
      foreground = "#303446"
      background = "#a6d189"

      [colors.footer_bar]
      foreground = "#303446"
      background = "#a5adce"

      [colors.hints.start]
      foreground = "#303446"
      background = "#e5c890"

      [colors.hints.end]
      foreground = "#303446"
      background = "#a5adce"

      [colors.selection]
      text = "#303446"
      background = "#f2d5cf"

      [colors.normal]
      black = "#51576d"
      red = "#e78284"
      green = "#a6d189"
      yellow = "#e5c890"
      blue = "#8caaee"
      magenta = "#f4b8e4"
      cyan = "#81c8be"
      white = "#b5bfe2"

      [colors.bright]
      black = "#626880"
      red = "#e78284"
      green = "#a6d189"
      yellow = "#e5c890"
      blue = "#8caaee"
      magenta = "#f4b8e4"
      cyan = "#81c8be"
      white = "#a5adce"

      [colors.dim]
      black = "#51576d"
      red = "#e78284"
      green = "#a6d189"
      yellow = "#e5c890"
      blue = "#8caaee"
      magenta = "#f4b8e4"
      cyan = "#81c8be"
      white = "#b5bfe2"

      [[colors.indexed_colors]]
      index = 16
      color = "#ef9f76"

      [[colors.indexed_colors]]
      index = 17
      color = "#f2d5cf"
    '';
  };

  # alacritty colorschemes
  home.file.".config/alacritty/catppuccin-latte.toml" = {
    executable = false;
    text = ''
      [colors.primary]
      background = "#eff1f5"
      foreground = "#4c4f69"
      dim_foreground = "#8c8fa1"
      bright_foreground = "#4c4f69"

      [colors.cursor]
      text = "#eff1f5"
      cursor = "#dc8a78"

      [colors.vi_mode_cursor]
      text = "#eff1f5"
      cursor = "#7287fd"

      [colors.search.matches]
      foreground = "#eff1f5"
      background = "#6c6f85"

      [colors.search.focused_match]
      foreground = "#eff1f5"
      background = "#40a02b"

      [colors.footer_bar]
      foreground = "#eff1f5"
      background = "#6c6f85"

      [colors.hints.start]
      foreground = "#eff1f5"
      background = "#df8e1d"

      [colors.hints.end]
      foreground = "#eff1f5"
      background = "#6c6f85"

      [colors.selection]
      text = "#eff1f5"
      background = "#dc8a78"

      [colors.normal]
      black = "#bcc0cc"
      red = "#d20f39"
      green = "#40a02b"
      yellow = "#df8e1d"
      blue = "#1e66f5"
      magenta = "#ea76cb"
      cyan = "#179299"
      white = "#5c5f77"

      [colors.bright]
      black = "#acb0be"
      red = "#d20f39"
      green = "#40a02b"
      yellow = "#df8e1d"
      blue = "#1e66f5"
      magenta = "#ea76cb"
      cyan = "#179299"
      white = "#6c6f85"

      [colors.dim]
      black = "#bcc0cc"
      red = "#d20f39"
      green = "#40a02b"
      yellow = "#df8e1d"
      blue = "#1e66f5"
      magenta = "#ea76cb"
      cyan = "#179299"
      white = "#5c5f77"

      [[colors.indexed_colors]]
      index = 16
      color = "#fe640b"

      [[colors.indexed_colors]]
      index = 17
      color = "#dc8a78"
    '';
  };

  # alacritty colorschemes
  home.file.".config/alacritty/catppuccin-macchiato.toml" = {
    executable = false;
    text = ''
      [colors.primary]
      background = "#24273a"
      foreground = "#cad3f5"
      dim_foreground = "#8087a2"
      bright_foreground = "#cad3f5"

      [colors.cursor]
      text = "#24273a"
      cursor = "#f4dbd6"

      [colors.vi_mode_cursor]
      text = "#24273a"
      cursor = "#b7bdf8"

      [colors.search.matches]
      foreground = "#24273a"
      background = "#a5adcb"

      [colors.search.focused_match]
      foreground = "#24273a"
      background = "#a6da95"

      [colors.footer_bar]
      foreground = "#24273a"
      background = "#a5adcb"

      [colors.hints.start]
      foreground = "#24273a"
      background = "#eed49f"

      [colors.hints.end]
      foreground = "#24273a"
      background = "#a5adcb"

      [colors.selection]
      text = "#24273a"
      background = "#f4dbd6"

      [colors.normal]
      black = "#494d64"
      red = "#ed8796"
      green = "#a6da95"
      yellow = "#eed49f"
      blue = "#8aadf4"
      magenta = "#f5bde6"
      cyan = "#8bd5ca"
      white = "#b8c0e0"

      [colors.bright]
      black = "#5b6078"
      red = "#ed8796"
      green = "#a6da95"
      yellow = "#eed49f"
      blue = "#8aadf4"
      magenta = "#f5bde6"
      cyan = "#8bd5ca"
      white = "#a5adcb"

      [colors.dim]
      black = "#494d64"
      red = "#ed8796"
      green = "#a6da95"
      yellow = "#eed49f"
      blue = "#8aadf4"
      magenta = "#f5bde6"
      cyan = "#8bd5ca"
      white = "#b8c0e0"

      [[colors.indexed_colors]]
      index = 16
      color = "#f5a97f"

      [[colors.indexed_colors]]
      index = 17
      color = "#f4dbd6"
    '';
  };

  # alacritty colorschemes
  home.file.".config/alacritty/catppuccin-mocha.toml" = {
    executable = false;
    text = ''
      [colors.primary]
      background = "#1e1e2e"
      foreground = "#cdd6f4"
      dim_foreground = "#7f849c"
      bright_foreground = "#cdd6f4"

      [colors.cursor]
      text = "#1e1e2e"
      cursor = "#f5e0dc"

      [colors.vi_mode_cursor]
      text = "#1e1e2e"
      cursor = "#b4befe"

      [colors.search.matches]
      foreground = "#1e1e2e"
      background = "#a6adc8"

      [colors.search.focused_match]
      foreground = "#1e1e2e"
      background = "#a6e3a1"

      [colors.footer_bar]
      foreground = "#1e1e2e"
      background = "#a6adc8"

      [colors.hints.start]
      foreground = "#1e1e2e"
      background = "#f9e2af"

      [colors.hints.end]
      foreground = "#1e1e2e"
      background = "#a6adc8"

      [colors.selection]
      text = "#1e1e2e"
      background = "#f5e0dc"

      [colors.normal]
      black = "#45475a"
      red = "#f38ba8"
      green = "#a6e3a1"
      yellow = "#f9e2af"
      blue = "#89b4fa"
      magenta = "#f5c2e7"
      cyan = "#94e2d5"
      white = "#bac2de"

      [colors.bright]
      black = "#585b70"
      red = "#f38ba8"
      green = "#a6e3a1"
      yellow = "#f9e2af"
      blue = "#89b4fa"
      magenta = "#f5c2e7"
      cyan = "#94e2d5"
      white = "#a6adc8"

      [colors.dim]
      black = "#45475a"
      red = "#f38ba8"
      green = "#a6e3a1"
      yellow = "#f9e2af"
      blue = "#89b4fa"
      magenta = "#f5c2e7"
      cyan = "#94e2d5"
      white = "#bac2de"

      [[colors.indexed_colors]]
      index = 16
      color = "#fab387"

      [[colors.indexed_colors]]
      index = 17
      color = "#f5e0dc"
    '';
  };
}
