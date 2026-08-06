{ pkgs, ... }:

{
  environment.systemPackages = [ pkgs.proton-vpn-cli ];

  # ProtonVPN CLI needs the network-manager-openvpn plugin
  networking.networkmanager.plugins = [ pkgs.networkmanager-openvpn ];
}
