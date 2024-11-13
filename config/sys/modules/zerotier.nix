{ ... }:
{
  services.zerotierone = {
    enable = true;
    # To remove networks, use the ZeroTier CLI: zerotier-cli leave <network-id>
    joinNetworks = [ "632ea290855db081" ];
  };
}
