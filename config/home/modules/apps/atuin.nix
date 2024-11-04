{ ... }:
{
  programs.atuin = {
    enable = true;
    enableNushellIntegration = true;
    settings = {
      auto_sync = false;
      # sync_frequency = "5m";
      # sync_address = "https://api.atuin.sh";
      # search_mode = "prefix";
    };
  };
}
