{ scaleFactor, terminalFontFamily }:
let
  baseFontSize = 13;
in
{
  # foot terminal
  programs.foot = {
    enable = true;
  };

  # foot terminal config + catppuccin mocha colors
  home.file.".config/foot/foot.ini" = {
    executable = false;
    text = ''
      initial-window-size-chars=82x23
      initial-window-mode=windowed
      pad=15x15
      resize-delay-ms=100

      font=${terminalFontFamily}:size=${toString (baseFontSize * scaleFactor) }
      #font-bold=JetBrainsMono Nerd Font:size=${toString (baseFontSize * scaleFactor) }
      #font-italic=JetBrainsMono Nerd Font:size=${toString (baseFontSize * scaleFactor) }
      #font-bold-italic=JetBrainsMono Nerd Font:size=${toString (baseFontSize * scaleFactor) }
      #line-height=10
      #letter-spacing=0
      #horizontal-letter-offset=0
      #vertical-letter-offset=0
      #underline-offset=0
      #box-drawings-uses-font-glyphs=no
      #dpi-aware=no

      [scrollback]
      lines=1000
      multiplier=3.0

      [cursor]
      style=block
      blink=yes

      [mouse]
      hide-when-typing=yes
      alternate-scroll-mode=yes

      [colors]
      alpha=1
      foreground=d9e0ee
      background=1E1E2E
      # background=11111b

      ## Normal/regular colors (color palette 0-7)
      regular0=51576d  # black
      regular1=e78284  # red
      regular2=a6d189  # green
      regular3=e5c890  # yellow
      regular4=8caaee  # blue
      regular5=f4b8e4  # magenta
      regular6=81c8be  # cyan
      regular7=b5bfe2  # white

      ## Bright colors (color palette 8-15)
      bright0=626880   # bright black
      bright1=e78284   # bright red
      bright2=a6d189   # bright green
      bright3=e5c890   # bright yellow
      bright4=8caaee   # bright blue
      bright5=f4b8e4   # bright magenta
      bright6=81c8be   # bright cyan
      bright7=a5adce   # bright white

      [csd]
      preferred=server
      size=0
      # font=<primary font>
      # color=abe9b3
      # hide-when-typing=no
      border-width=1
      # border-color=abe9b3
      button-width=0
      # button-color=<background color>
      # button-minimize-color=<regular4>
      # button-maximize-color=<regular2>
      # button-close-color=<regular1>
    '';
  };
}
