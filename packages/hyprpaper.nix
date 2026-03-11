{
  config,
  pkgs,
  ...
}: let
  selected_wallpaper_path = (import ./wallpaper.nix config).wallpaper_path;
in {
  home.file = {
    "Pictures/Wallpapers" = {
      source = ../assets/themes/wallpapers;
      recursive = true;
    };
  };

  home.packages = [ pkgs.swww ];

  # swww replaces hyprpaper: faster startup, smooth transitions, reliable IPC
  # swww-daemon + initial wallpaper set in hyprland/autostart.nix
  services.hyprpaper.enable = false;
}
