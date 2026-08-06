{ ... }: {
  # Sonos speakers reply to SSDP M-SEARCH from a *random* source port to our
  # ephemeral source port — and because the M-SEARCH went to a multicast
  # destination, conntrack can't match the unicast reply as RELATED, so the
  # firewall blocks it. Workaround: trust UDP from the LAN subnet so SSDP
  # replies (and UPnP event callbacks) reach noson regardless of port.
  # TCP 1400 is the noson event callback (speakers POST notifications here).
  networking.firewall.allowedUDPPorts = [ 1900 ];
  networking.firewall.allowedTCPPorts = [ 1400 ];
  networking.firewall.extraCommands = ''
    iptables -I nixos-fw -s 192.168.12.0/24 -p udp -j nixos-fw-accept
  '';
}
