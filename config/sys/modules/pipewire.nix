{ pkgs, ... }:

{
  hardware.pulseaudio.enable = false;

  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    jack.enable = true;
    pulse.enable = true;
    wireplumber = {
      enable = true;
      package = pkgs.wireplumber;
    };
  };

  # sound.enable = true;
}
