{
  config,
  pkgs,
  ...
}: let
  hexToRgba = hex: alpha: let
  in "rgba(${hex}${alpha})";

  inactiveBorder = hexToRgba config.colorScheme.palette.base09 "aa";
  activeBorder = hexToRgba config.colorScheme.palette.base0D "aa";
  activeBorder2 = hexToRgba config.colorScheme.palette.base0E "aa";
in {
  wayland.windowManager.hyprland.settings = {
    general = {
      gaps_in = 3;
      gaps_out = 6;

      border_size = 2;

      "col.active_border" = "${activeBorder} ${activeBorder2} 45deg";
      "col.inactive_border" = inactiveBorder;

      resize_on_border = false;

      allow_tearing = false;

      layout = "dwindle";
    };

    decoration = {
      rounding = 14;

      active_opacity = 0.97;
      inactive_opacity = 0.93;
      dim_inactive = true;
      dim_strength = 0.15;

      shadow = {
        enabled = true;
        range = 20;
        render_power = 2;
        color = "rgba(00000050)";
      };

      blur = {
        enabled = true;
        size = 5;
        passes = 2;

        vibrancy = 0.1696;
        special = true;
        popups = true;
        popups_ignorealpha = 0.2;
      };
    };

    animations = {
      enabled = true; # yes, please :)

      bezier = [
        "easeOutQuint,0.23,1,0.32,1"
        "easeInOutCubic,0.65,0.05,0.36,1"
        "linear,0,0,1,1"
        "almostLinear,0.5,0.5,0.75,1.0"
        "quick,0.15,0,0.1,1"
      ];

      animation = [
        "global, 1, 10, default"
        "border, 1, 5.39, easeOutQuint"
        "windows, 1, 4.79, easeOutQuint"
        "windowsIn, 1, 3.5, easeOutQuint, popin 80%"
        "windowsOut, 1, 1.2, almostLinear, popin 80%"
        "fadeIn, 1, 1.73, almostLinear"
        "fadeOut, 1, 1.46, almostLinear"
        "fade, 1, 3.03, quick"
        "layers, 1, 3.81, easeOutQuint"
        "layersIn, 1, 4, easeOutQuint, fade"
        "layersOut, 1, 1.5, linear, fade"
        "fadeLayersIn, 1, 1.79, almostLinear"
        "fadeLayersOut, 1, 1.39, almostLinear"
        "fadeDim, 1, 6, almostLinear"
        "workspaces, 1, 3.5, easeOutQuint, slidefadevert 15%"
        "specialWorkspace, 1, 4, easeOutQuint, slidevert"
      ];
    };

    dwindle = {
      preserve_split = true;
      force_split = 2;
    };

    master = {
      new_status = "master";
    };

    misc = {
      disable_hyprland_logo = true;
      disable_splash_rendering = true;
    };

    input = {
      numlock_by_default = true;
    };
  };
}
