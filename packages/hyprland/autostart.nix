{
  config,
  pkgs,
  ...
}: {
  wayland.windowManager.hyprland.settings = {
    exec-once = [
      "awww-daemon"
      "sleep 1 && theme-switch random"
      "hyprsunset"
      "systemctl --user start hyprpolkitagent"
      "wl-paste --type text --watch cliphist store"
      "wl-paste --type image --watch cliphist store"
      "xwaylandvideobridge"
      "1password --silent"
      "todo-panel-toggle --autostart"
      "wattson-toggle --autostart"
    ];

    exec = [
      "pkill -SIGUSR2 waybar || waybar"
    ];
  };
}
