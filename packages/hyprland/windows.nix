{
  config,
  pkgs,
  ...
}: {
  wayland.windowManager.hyprland.settings = {
    windowrule = [
      # Eternl Cardano wallet (Brave PWA)
      "float true, match:class ^(brave-kmhcihpebfmpgmihbkipmjlmmioameka-Default)$"

      # Brave download/save dialogs
      "float true, match:class ^(brave)$, match:title ^(wants to save).*"
      "pin true, match:class ^(brave)$, match:title ^(wants to save).*"
      "size 941 250, match:class ^(brave)$, match:title ^(wants to save).*"
      "center true, match:class ^(brave)$, match:title ^(wants to save).*"

      # Other common Brave dialogs
      "float true, match:class ^(brave)$, match:title ^(Open File)$"
      "float true, match:class ^(brave)$, match:title ^(Save File)$"
      "float true, match:class ^(brave)$, match:title ^(Select Files)$"
      "pin true, match:class ^(brave)$, match:title ^(Open File)$"
      "pin true, match:class ^(brave)$, match:title ^(Save File)$"
      "pin true, match:class ^(brave)$, match:title ^(Select Files)$"

      # Default these to floating
      "float true, match:class ^(org.pulseaudio.pavucontrol|blueberry.py)$"
      "float true, match:class ^(steam)$"
      "fullscreen true, match:class ^(com.libretro.RetroArch)$"

      # Opacity rules
      "opacity 1.0 1.0, match:class ^(brave|chromium|google-chrome)$, match:title .*[Yy]ou[Tt]ube.*"
      "opacity 1.0 0.97, match:class ^(brave|chromium|google-chrome)$"
      "opacity 1.0 1.0, match:class ^(zoom|vlc|kdenlive|com.obsproject.Studio)$"

      # Fix XWayland dragging
      "no_focus true, match:class ^$, match:title ^$, match:xwayland true, match:float true, match:fullscreen false, match:pin false"


      # Clipse clipboard manager
      "float true, match:class ^(clipse)$"
      "size 622 652, match:class ^(clipse)$"
      "stay_focused true, match:class ^(clipse)$"

      # System utilities
      "size 800 600, match:class ^(org.pulseaudio.pavucontrol)$"
      "center true, match:class ^(org.pulseaudio.pavucontrol)$"

      "size 700 500, match:class ^(blueberry.py)$"
      "center true, match:class ^(blueberry.py)$"

      # Network manager
      "float true, match:class ^(nm-connection-editor)$"
      "size 600 500, match:class ^(nm-connection-editor)$"
      "center true, match:class ^(nm-connection-editor)$"

      # Calculator
      "float true, match:class ^(org.gnome.Calculator|qalculate-gtk)$"
      "size 400 500, match:class ^(org.gnome.Calculator|qalculate-gtk)$"
      "center true, match:class ^(org.gnome.Calculator|qalculate-gtk)$"

      # File pickers
      "float true, match:class ^(xdg-desktop-portal-gtk)$, match:title ^(.*File.*|.*Open.*|.*Save.*)$"
      "size 900 600, match:class ^(xdg-desktop-portal-gtk)$, match:title ^(.*File.*|.*Open.*|.*Save.*)$"
      "center true, match:class ^(xdg-desktop-portal-gtk)$, match:title ^(.*File.*|.*Open.*|.*Save.*)$"

      # Picture-in-Picture
      "float true, match:title ^(Picture-in-Picture)$"
      "size 25% 25%, match:title ^(Picture-in-Picture)$"
      "pin true, match:title ^(Picture-in-Picture)$"
      "move 72% 72%, match:title ^(Picture-in-Picture)$"

      # Max size constraint
      "max_size 1400 900, match:float true"

      # Prevent screen from sleeping
      "idle_inhibit fullscreen, match:class ^(brave|chromium|firefox)$"
      "idle_inhibit focus, match:class ^(mpv|vlc|celluloid)$"
      "idle_inhibit focus, match:class ^(com.obsproject.Studio)$"

      # Hide xwaylandvideobridge
      "opacity 0.0 override, match:class ^(xwaylandvideobridge)$"
      "no_anim true, match:class ^(xwaylandvideobridge)$"
      "no_initial_focus true, match:class ^(xwaylandvideobridge)$"
      "max_size 1 1, match:class ^(xwaylandvideobridge)$"
      "no_blur true, match:class ^(xwaylandvideobridge)$"

      # Misc
      "tile true, match:class ^(chromium)$"
      "suppress_event maximize, match:class .*"
    ];

    layerrule = [
      "blur true, match:namespace wofi"
      "blur true, match:namespace waybar"
    ];
  };
}
