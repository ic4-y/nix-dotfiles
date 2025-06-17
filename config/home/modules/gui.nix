{ pkgs, ... }:

let
  wrapped-bitwarden = (pkgs.writeShellScriptBin "bitwarden" ''
    exec ${pkgs.bitwarden}/bin/bitwarden --disable-gpu
  '');

  wrapped-chromium = (pkgs.writeShellScriptBin "chromium" ''
    exec firejail ${pkgs.chromium}/bin/chromium
  '');

  wrapped-discord = (pkgs.writeShellScriptBin "Discord" ''
    exec firejail ${pkgs.discord}/bin/discord --disable-gpu
  '');

  wrapped-firefox = (pkgs.writeShellScriptBin "firefox" ''
    exec firejail ${pkgs.firefox}/bin/firefox
  '');
in
{
  home.packages = with pkgs; [

    simp1e-cursor-theme-catppuccin-frappe
    # diogenes-reader
    unstable.galaxy-buds-client

    # pass --disable-gpu to bitwarden desktop via wrapper
    (symlinkJoin {
      name = "bitwarden";
      paths = [
        wrapped-bitwarden
        bitwarden
      ];
    })

    unstable.darktable

    # thunderbird, tutanota
    unstable.thunderbird
    unstable.tutanota-desktop

    unstable.obs-studio
    unstable.obs-studio-plugins.wlrobs

    # To-do task manager
    unstable.endeavour

    # signal, telegram, whatsapp, element, zulip
    unstable.signal-desktop
    unstable.tdesktop
    unstable.whatsapp-for-linux
    # unstable.element-desktop
    unstable.zulip
    unstable.mattermost-desktop

    # OnlyOffice
    unstable.onlyoffice-bin

    # display color calibration 
    unstable.displaycal

    # Obsidian
    unstable.obsidian

    # Jan.ai ChatGPT-like local app
    unstable.jan

    # Creating a wrapper for discord to run it in firejail and with --disable-gpu
    (symlinkJoin {
      name = "discord";
      paths = [
        wrapped-discord
        pkgs.discord
      ];
    })

    # Alternative Discord desktop client
    unstable.vesktop

    # bruno API client, bye bye insomnia
    unstable.bruno

    # hoppscotch, alternative to bruno/postman/insomnia
    unstable.hoppscotch

    vlc

    # notetaking app
    unstable.rnote

    # wallpapers from unsplash
    unstable.fondo
    # background sounds
    unstable.blanket
    # Extract text from image
    unstable.gnome-frog
    # upscayl AI image upscaler
    unstable.upscayl

    # GPU screen recorder
    unstable.gpu-screen-recorder
    unstable.gpu-screen-recorder-gtk

    # Web Video downloader GUI for yt-dlp
    parabolic

    # Calibre ebooks
    calibre

    # Creating a wrapper for chromium to run it in firejail
    (symlinkJoin {
      name = "chromium";
      paths = [
        wrapped-chromium
        pkgs.chromium
      ];
    })

    # Creating a wrapper for firefox to run it in firejail
    (symlinkJoin {
      name = "firefox";
      paths = [
        wrapped-firefox
        pkgs.firefox
      ];
    })

    # Librewolf
    unstable.librewolf

    # Tor-Browser
    unstable.tor-browser-bundle-bin

    # Zotero
    unstable.zotero

  ];

  programs.brave = {
    enable = true;
    package = pkgs.brave;
    # commandLineArgs = [
    #   "--enable-features=Vulkan,DefaultANGLEVulkan,VulkanFromANGLE,VaapiVideoEncoder,VaapiVideoDecoder,VaapiIgnoreDriverChecks,VaapiVideoDecodeLinuxGL"
    #   "--use-gl=angle"
    #   "--use-angle=gl"
    #   "--ozone-platform=wayland"
    # ];
  };
}
