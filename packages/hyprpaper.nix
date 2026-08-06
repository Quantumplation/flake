{ pkgs, ... }: {
  home.file."Pictures/Wallpapers" = {
    source = ../assets/themes/wallpapers;
    recursive = true;
  };

  # awww (formerly swww) replaces hyprpaper: faster startup, smooth transitions, reliable IPC
  # awww-daemon + initial wallpaper set in hyprland/autostart.nix
  home.packages = [ pkgs.awww ];
}
