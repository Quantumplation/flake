{
  config,
  pkgs,
  ...
}: {
  wayland.windowManager.hyprland.settings = {
    windowrulev2 = [
      # Eternl Cardano wallet transaction signing popup
      "float, title:^(Eternl Cardano light wallet)$"
      "pin, title:^(Eternl Cardano light wallet)$"
      "stayfocused, title:^(Eternl Cardano light wallet)$"

      # Brave download/save dialogs
      "float, class:^(brave)$, title:^(wants to save).*"
      "pin, class:^(brave)$, title:^(wants to save).*"
      "size 941 250, class:^(brave)$, title:^(wants to save).*"
      "center, class:^(brave)$, title:^(wants to save).*"

      # Other common Brave dialogs
      "float, class:^(brave)$, title:^(Open File)$"
      "float, class:^(brave)$, title:^(Save File)$"
      "float, class:^(brave)$, title:^(Select Files)$"
      "pin, class:^(brave)$, title:^(Open File)$"
      "pin, class:^(brave)$, title:^(Save File)$"
      "pin, class:^(brave)$, title:^(Select Files)$"

      # Default these to floating
      "float, class:^(org.pulseaudio.pavucontrol|blueberry.py)$"
      "float, class:^(steam)$"
      "fullscreen, class:^(com.libretro.RetroArch)$"

      # Opacity rules with multiple conditions
      "opacity 1.0 1.0, class:^(brave|chromium|google-chrome)$, title:.*[Yy]ou[Tt]ube.*"
      "opacity 1.0 0.97, class:^(brave|chromium|google-chrome)$"
      "opacity 1.0 1.0, class:^(zoom|vlc|kdenlive|com.obsproject.Studio)$"

      # Fix XWayland dragging
      "nofocus, class:^$, title:^$, xwayland:1, floating:1, fullscreen:0, pinned:0"

      # Clipse clipboard manager
      "float, class:^(clipse)$"
      "size 622 652, class:^(clipse)$"
      "stayfocused, class:^(clipse)$"

      # System utilities - sensible sizes
      "size 800 600, class:^(org.pulseaudio.pavucontrol)$"
      "center, class:^(org.pulseaudio.pavucontrol)$"

      "size 700 500, class:^(blueberry.py)$"
      "center, class:^(blueberry.py)$"

      # Network manager
      "float, class:^(nm-connection-editor)$"
      "size 600 500, class:^(nm-connection-editor)$"
      "center, class:^(nm-connection-editor)$"

      # Calculator
      "float, class:^(org.gnome.Calculator|qalculate-gtk)$"
      "size 400 500, class:^(org.gnome.Calculator|qalculate-gtk)$"
      "center, class:^(org.gnome.Calculator|qalculate-gtk)$"

      # File pickers (general XDG portal)
      "float, title:^(.*File.*|.*Open.*|.*Save.*)$, class:^(xdg-desktop-portal-gtk)$"
      "size 900 600, title:^(.*File.*|.*Open.*|.*Save.*)$, class:^(xdg-desktop-portal-gtk)$"
      "center, title:^(.*File.*|.*Open.*|.*Save.*)$, class:^(xdg-desktop-portal-gtk)$"

      # Picture-in-Picture
      "float, title:^(Picture-in-Picture)$"
      "size 25% 25%, title:^(Picture-in-Picture)$"
      "pin, title:^(Picture-in-Picture)$"
      "move 72% 72%, title:^(Picture-in-Picture)$"  # Bottom-right corner

      # Max size constraint to prevent full-screen takeover
      "maxsize 1400 900, floating:1"

      # Prevent screen from sleeping
      "idleinhibit fullscreen, class:^(brave|chromium|firefox)$"
      "idleinhibit focus, class:^(mpv|vlc|celluloid)$"
      "idleinhibit focus, class:^(com.obsproject.Studio)$"  # OBS

      # Hide xwaylandvideobridge
      "opacity 0.0 override, class:^(xwaylandvideobridge)$"
      "noanim, class:^(xwaylandvideobridge)$"
      "noinitialfocus, class:^(xwaylandvideobridge)$"
      "maxsize 1 1, class:^(xwaylandvideobridge)$"
      "noblur, class:^(xwaylandvideobridge)$"
    ];

    windowrule = [
      "suppressevent maximize, class:.*"
      "tile, class:^(chromium)$"
    ];

    layerrule = [
      # Proper background blur for wofi
      "blur,wofi"
      "blur,waybar"
    ];
  };
}
