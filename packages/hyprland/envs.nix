{
  config,
  lib,
  pkgs,
  osConfig ? {},
  ...
}: {
  # NOTE: no session-wide NVIDIA env vars here, deliberately.
  #
  # Exporting __GLX_VENDOR_LIBRARY_NAME=nvidia / GBM_BACKEND=nvidia-drm to the
  # whole session pushes *every* GL/EGL client onto the dGPU — including things
  # with no business there, like the notification daemon. Each client that opens
  # /dev/nvidia* pins the GPU awake and defeats runtime PM: the RTX 5070 sat in
  # P8 at 0% utilization drawing 5.84W, runtime-suspended for 0.6s out of 20.8h.
  #
  # The display (eDP-1) is on the AMD iGPU, so nothing needs the dGPU by default.
  # For apps that genuinely want it, use the `nvidia-offload` wrapper
  # (hardware.nvidia.prime.offload.enableOffloadCmd), which sets these same vars
  # per-process — e.g. `nvidia-offload steam`.
  #
  # LIBVA_DRIVER_NAME is likewise left alone: hosts/noether sets radeonsi, and
  # forcing nvidia there breaks browser video decode (the NVDEC driver ignores
  # the render node it's handed and always targets the dGPU).
  wayland.windowManager.hyprland.settings = {
    cursor = {
      no_hardware_cursors = true;
      no_warps = false;
    };

    env = [
        # GTK4 defaults to the Vulkan renderer, and the Vulkan loader enumerates
        # *every* installed ICD — including nvidia_icd.json. Merely enumerating it
        # opens /dev/nvidia0 + nvidia-modeset, which pins the dGPU awake and
        # defeats runtime PM. swaync (a GTK4 app) was doing exactly this. The GL
        # renderer skips Vulkan entirely and stays on the AMD iGPU; verified that
        # swaync then holds only renderD128.
        # NB: the value is "gl", not "ngl" — GTK renamed the new GL renderer, and
        # an unrecognized name only warns and silently falls back to Vulkan,
        # which would quietly undo the above.
        "GSK_RENDERER,gl"

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

        # XDG Desktop Portal
        "XDG_CURRENT_DESKTOP,Hyprland"
        "XDG_SESSION_TYPE,wayland"
        "XDG_SESSION_DESKTOP,Hyprland"

        # Use XCompose file
        "XCOMPOSEFILE,~/.XCompose"
        "EDITOR,vim"

        "GTK_THEME,Adwaita:dark"

        # XWayland scaling (for force_zero_scaling)
        "GDK_SCALE,2"
        "QT_SCALE_FACTOR,1.6"
      ];

    xwayland = {
      force_zero_scaling = true;
    };

    # Don't show update on first launch
    ecosystem = {
      no_update_news = true;
    };
  };
}
