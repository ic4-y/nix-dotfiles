{ pkgs, ... }:
{
  home.packages = with pkgs.unstable; [
    whisper-cpp-vulkan
  ];
}
