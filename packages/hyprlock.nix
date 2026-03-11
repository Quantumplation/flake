inputs: {
  config,
  pkgs,
  lib,
  ...
}: let
  palette = config.colorScheme.palette;
  convert = inputs.nix-colors.lib.conversions.hexToRGBString;
  selected_wallpaper_path = (import ./wallpaper.nix config).wallpaper_path;

  backgroundRgb = "rgba(${convert ", " palette.base00}, 0.8)";
  surfaceRgb = "rgb(${convert ", " palette.base02})";
  foregroundRgb = "rgb(${convert ", " palette.base05})";
  foregroundMutedRgb = "rgb(${convert ", " palette.base04})";
in {
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
        path = selected_wallpaper_path;
        blur_passes = 3;
        brightness = 0.5;
      };

      input-field = {
        monitor = "";
        size = "600, 100";
        position = "0, 0";
        halign = "center";
        valign = "center";

        inner_color = surfaceRgb;
        outer_color = foregroundRgb; # #d3c6aa
        outline_thickness = 4;

        font_family = "CaskaydiaMono Nerd Font";
        font_size = 32;
        font_color = foregroundRgb;

        placeholder_color = foregroundMutedRgb;
        placeholder_text = "  Enter Password 󰈷 ";
        check_color = "rgba(131, 192, 146, 1.0)";
        fail_text = "Wrong";

        rounding = 14;
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
