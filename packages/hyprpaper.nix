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
  services.hyprpaper = {
    enable = true;
    settings = {
      preload = [
        selected_wallpaper_path
      ];
      wallpaper = [
        ",${selected_wallpaper_path}"
      ];
    };
  };

  # hyprpaper races with Hyprland monitor init — delay startup slightly
  systemd.user.services.hyprpaper.Service.ExecStartPre = "${pkgs.coreutils}/bin/sleep 2";
}
