{
  config,
  pkgs,
  ...
}: {
  wayland.windowManager.hyprland.settings = {
    bind = [
      # Launcher
      "SUPER, space, exec, wofi --show drun --sort-order alphabetical"
      "SUPER SHIFT, SPACE, exec, pkill -SIGUSR1 waybar"

      # Clipboard management
      "SUPER, V, exec, clipboard-manager menu"
      "SUPER SHIFT, V, exec, clipboard-manager snippets"
      "SUPER CTRL, V, exec, clipboard-manager clear-all"

      # Kill / exit / shutdown
      "SUPER, W, killactive"
      "SUPER, ESCAPE, exec, hyprlock"
      "SUPER, Y, exec, wofi-power-menu"

      # Tiling
      "SUPER, grave, togglesplit, # dwindle"
      "SUPER, S, togglefloating,"
      "SUPER, M, fullscreen, 1"
      "SUPER SHIFT, M, fullscreen, 0"

      # Cycling
      "ALT, Tab, cyclenext,"
      "ALT, Tab, bringactivetotop,"
      "ALT SHIFT, Tab, cyclenext, prev"
      "ALT SHIFT, Tab, bringactivetotop"
      "SUPER CTRL, Tab, split-cycleworkspaces, next"
      "SUPER, R, exec, hypr-snap-back"

      # Key Light controls (SUPER + L for Light)
      "SUPER, L, exec, keylight toggle"
      "SUPER SHIFT, L, exec, keylight brighter"
      "SUPER CTRL, L, exec, keylight dimmer"
      "SUPER ALT, L, exec, keylight preset recording"

      # Volume
      "SUPER, O, exec, audio-switch cycle"
      "SUPER SHIFT, O, exec, audio-switch wofi"
      "SUPER CTRL, O, exec, wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"
      "SUPER, equal, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+"
      "SUPER, minus, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"

      # Screenshotting
      "CTRL SHIFT, 4, exec, hyprshot -m region"

      # Applications
      "SUPER, A, exec, $terminal"
      "SUPER, B, exec, $browser"
      "SUPER, C, exec, $messenger"
      "SUPER, D, exec, discord"
      "SUPER, E, exec, zeditor"
      "SUPER, Z, exec, zeditor"
      "SUPER, F, exec, nautilus" 
    ];

    bindm = [
      "SUPER, mouse:272, movewindow"
      "SUPER, mouse:273, resizewindow"
    ];
  };
}
