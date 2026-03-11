config: let
  themes = import ../modules/themes.nix;
  selected_wallpaper = themes.${themes.selected}.wallpaper;
  wallpaper_path = "${config.home.homeDirectory}/Pictures/Wallpapers/${selected_wallpaper}";
in {
  inherit wallpaper_path;
}
