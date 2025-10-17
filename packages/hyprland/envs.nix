{
  config,
  lib,
  pkgs,
  osConfig ? {},
  ...
}: let
  hasNvidiaDrivers = builtins.elem "nvidia" osConfig.services.xserver.videoDrivers;
  nvidiaEnv = [
    "NVD_BACKEND,direct"
    "LIBVA_DRIVER_NAME,nvidia"
    "__GLX_VENDOR_LIBRARY_NAME,nvidia"
    "GBM_BACKEND,nvidia-drm"
  ];
in {
  wayland.windowManager.hyprland.settings = {
    cursor = {
      no_hardware_cursors = true;
      no_warps = false;
    };

    env =
      (lib.optionals hasNvidiaDrivers nvidiaEnv)
      ++ [
        # Cursor size
        "XCURSOR_SIZE,24"
        "HYPRCURSOR_SIZE,24"

        # Cursor theme
        "XCURSOR_THEME,Adwaita"
        "HYPRCURSOR_THEME,Adwaita"

        # Tracing
        "HYPRLAND_TRACE,1"
        "AQ_TRACE,1"

        # Monitor workaround
        # "AQ_NO_MODIFIERS,1"

        # Force all apps to use wayland
        "GDK_BACKEND,wayland"
        "QT_QPA_PLATFORM,wayland"
        "QT_STYLE_OVERRIDE,kvantum"
        "SDL_VIDEODRIVER,wayland"
        "MOZ_ENABLE_WAYLAND,1"
        "ELECTRON_OZONE_PLATFORM_HINT,wayland"
        "OZONE_PLATFORM,wayland"

        # Make .desktop files available for wofi    
        "XDG_DATA_DIRS,$XDG_DATA_DIRS:$HOME/.nix-profile/share:/nix/var/nix/profiles/default/share"

        # Use XCompose file
        "XCOMPOSEFILE,~/.XCompose"
        "EDITOR,vim"

        "GTK_THEME,Adwaita:dark"
      ];

    xwayland = {
      # force_zero_scaling = true;
    };

    # Don't show update on first launch
    ecosystem = {
      no_update_news = true;
    };
  };
}
