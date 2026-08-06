{ pkgs, ... }: {
  # Vesktop rather than the official Discord client.
  #
  # Discord hard-gates outdated clients, and nixpkgs tracks its releases with a
  # lag (a pin only 4 days old still carried 1.0.138 while upstream served
  # 1.0.150). Because the Nix store is read-only, the client's own updater cannot
  # recover from that, so it just renders a blank window. Pinning the upstream
  # tarball in an overlay works but has to be re-hashed on every Discord release.
  #
  # Vesktop wraps Discord's *web* app in Electron, so there is no native client
  # version to gate and no hash to chase — this class of breakage goes away. It
  # also ships Vencord, and has better screenshare support on Wayland.
  #
  # Window class is "vesktop" (not "discord"); see snap-back, the waybar icon map
  # in hosts/noether, and the SUPER+D binding.
  environment.systemPackages = with pkgs; [
    vesktop
  ];
}
