{ scaleFactor, terminalFontFamily }:
let
  baseFontSize = 11;
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
      dpi-aware=no

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
      regular0=6e6c7e  # black
      regular1=f28fad  # red
      regular2=abe9b3  # green
      regular3=fae3b0  # yellow
      regular4=96cdfb  # blue
      regular5=f5c2e7  # magenta
      regular6=89dceb  # cyan
      regular7=d9e0ee  # white

      ## Bright colors (color palette 8-15)
      bright0=988ba2   # bright black
      bright1=f28fad   # bright red
      bright2=abe9b3   # bright green
      bright3=fae3b0   # bright yellow
      bright4=96cdfb   # bright blue
      bright5=f5c2e7   # bright magenta
      bright6=89dceb   # bright cyan
      bright7=d9e0ee   # bright white

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
