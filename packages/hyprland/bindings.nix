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

      # 1Password quick access
      "SUPER, P, exec, 1password --quick-access"
      "CTRL SHIFT, SPACE, exec, 1password --quick-access"

      # Kill / exit / shutdown
      "SUPER, W, killactive"
      "SUPER, ESCAPE, exec, hyprlock"
      "SUPER, Y, exec, wofi-power-menu"

      # Tiling
      "SUPER, grave, layoutmsg, togglesplit # dwindle"
      "SUPER, S, togglefloating,"
      "SUPER, M, fullscreen, 1"
      "SUPER SHIFT, M, fullscreen, 0"

      # Cycling - alt-tab is configured per-host
      # "SUPER CTRL, Tab, split-cycleworkspaces, next"
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
      "CTRL SHIFT, 4, exec, screenshot -m region"

      # Workspace management
      "SUPER, X, exec, swap-workspaces"

      # Theme
      "SUPER SHIFT, T, exec, theme-switch random"

      # Quake-style dropdown terminal
      "SUPER SHIFT, A, exec, quake-terminal"

      # Claude approval queue / session dashboard (Q = approval Queue).
      # Same toggle as the waybar click: opens the sliding panel, or closes
      # it if already open.
      "SUPER, Q, exec, claude-dropdown"

      # Todo panel (floating quick-add + list) / zero-UI selection capture
      "SUPER, T, exec, todo-panel-toggle"
      "SUPER CTRL, T, exec, todo-capture --selection"

      # Applications
      "SUPER, A, exec, $terminal"
      "SUPER, B, exec, $browser"
      "SUPER, C, exec, $messenger"
      "SUPER, D, exec, vesktop"
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
