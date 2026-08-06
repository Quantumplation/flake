{
  inputs,
  config,
  pkgs,
  lib,
  ...
}: let
  palette = config.colorScheme.palette;
  convert = inputs.nix-colors.lib.conversions.hexToRGBString;
  defaultWallpaperPath = (import ./wallpaper.nix config).wallpaper_path;
  # Stable symlink kept current by theme-switch; hyprlock reads through it
  # so the lock screen tracks whichever theme is active at runtime.
  lockWallpaperLink = "${config.home.homeDirectory}/.cache/lockscreen-wallpaper";

  backgroundRgb = "rgba(${convert ", " palette.base00}, 0.8)";
  surfaceRgb = "rgb(${convert ", " palette.base02})";
  foregroundRgb = "rgb(${convert ", " palette.base05})";
  foregroundMutedRgb = "rgb(${convert ", " palette.base04})";
in {
  # Seed the symlink at activation so hyprlock has a valid target on first
  # boot, before autostart runs `theme-switch random`.
  home.activation.lockscreenWallpaper = lib.hm.dag.entryAfter ["writeBoundary"] ''
    mkdir -p "$(dirname ${lockWallpaperLink})"
    ln -sfn "${defaultWallpaperPath}" "${lockWallpaperLink}"
  '';

  programs.hyprlock = {
    enable = true;
    settings = {
      general = {
        disable_loading_bar = true;
        no_fade_in = false;
      };
      auth = {
        fingerprint.enabled = true;
      };
      background = {
        monitor = "";
        path = lockWallpaperLink;
        blur_passes = 3;
        brightness = 0.5;
      };

      input-field = {
        monitor = "";
        size = "420, 60";
        position = "0, 0";
        halign = "center";
        valign = "center";

        inner_color = surfaceRgb;
        outer_color = foregroundRgb;
        outline_thickness = 2;

        font_family = "CaskaydiaMono Nerd Font";
        font_size = 22;
        font_color = foregroundRgb;

        placeholder_color = foregroundMutedRgb;
        placeholder_text = "";
        check_color = "rgba(131, 192, 146, 1.0)";
        fail_text = "";

        rounding = 12;
        shadow_passes = 0;
        fade_on_empty = false;
      };

      label = [
        {
          monitor = "";
          text = "cmd[update:1000] date +\"%I:%M %p\"";
          text_align = "center";
          color = foregroundRgb;
          font_size = 64;
          font_family = "CaskaydiaMono Nerd Font";
          position = "0, 200";
          halign = "center";
          valign = "center";
          shadow_passes = 1;
        }
        {
          monitor = "";
          text = "cmd[update:60000] date +\"%A, %B %d\"";
          text_align = "center";
          color = foregroundMutedRgb;
          font_size = 20;
          font_family = "CaskaydiaMono Nerd Font";
          position = "0, 140";
          halign = "center";
          valign = "center";
        }
        {
          monitor = "";
          text = "\$FPRINTPROMPT";
          text_align = "center";
          color = foregroundMutedRgb;
          font_size = 24;
          font_family = "CaskaydiaMono Nerd Font";
          position = "0, -100";
          halign = "center";
          valign = "center";
        }
      ];
    };
  };
}
