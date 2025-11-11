{ lib, pkgs, nixpak, makeDesktopItem, buildEnv, ... }:
let
  mkNixPak = nixpak.lib.nixpak {
    inherit (pkgs) lib;
    inherit pkgs;
  };

  appId = "org.mozilla.firefox";
  firefox-sandboxed = mkNixPak {
    config =
      { config, sloth, ... }:
      {
        app = {
          package = pkgs.firefox;
          binPath = "bin/firefox";
        };
        flatpak.appId = appId;

        imports = [
          ./common-mixin.nix
          { inherit lib sloth config pkgs; }
          # ./gui-mixin.nix { inherit config lib pkgs sloth nixpak; } # Not using gui-mixin directly as per user's instruction
        ];

        bubblewrap = {
          # To trace all the home files Firefox accesses, you can use the following nushell command:
          #   just trace-access firefox
          # See the Justfile in the root of this repository for more information.
          bind.rw = with sloth; [
            # given the read write permission to the following directories.
            # NOTE: sloth.mkdir is used to create the directory if it does not exist!
            (mkdir (concat' sloth.homeDir "/.mozilla"))

            xdgDocumentsDir
            xdgDownloadDir
            xdgMusicDir
            xdgVideosDir
            xdgPicturesDir
          ];
          bind.ro = with sloth; [
            "/sys/bus/pci"
            [
              "${pkgs.firefox-wayland}/lib/firefox"
              "/app/etc/firefox"
            ]

            # ================ for browserpass extension ===============================
            "/etc/gnupg"
            (concat' sloth.homeDir "/.gnupg") # gpg's config
            (concat' sloth.homeDir "/.local/share/password-store") # my secrets
            (concat' sloth.runtimeDir "/gnupg") # for access gpg-agent socket

            # Unsure
            (concat' sloth.xdgConfigHome "/dconf")
          ];

          sockets = {
            x11 = false;
            wayland = true;
            pipewire = true;
          };
        };
      };
  };
  exePath = lib.getExe firefox-sandboxed.config.script;
in
buildEnv {
  inherit (firefox-sandboxed.config.script) name meta passthru;
  paths = [
    firefox-sandboxed.config.script
    (makeDesktopItem {
      name = appId;
      desktopName = "Firefox";
      genericName = "Firefox Boxed";
      comment = "Firefox Browser";
      exec = "${exePath} %U";
      terminal = false;
      icon = "firefox";
      startupNotify = true;
      startupWMClass = "firefox";
      type = "Application";
      categories = [
        "Network"
        "WebBrowser"
      ];
      mimeTypes = [
        "text/html"
        "text/xml"
        "application/xhtml+xml"
        "application/vnd.mozilla.xul+xml"
        "x-scheme-handler/http"
        "x-scheme-handler/https"
      ];

      actions = {
        new-private-window = {
          name = "New Private Window";
          exec = "${exePath} --private-window %U";
        };
        new-window = {
          name = "New Window";
          exec = "${exePath} --new-window %U";
        };
        profile-manager-window = {
          name = "Profile Manager";
          exec = "${exePath} --ProfileManager";
        };
      };

      extraConfig = {
        X-Flatpak = appId;
      };
    })
  ];
}
