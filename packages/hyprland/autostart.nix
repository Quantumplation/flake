{
  config,
  pkgs,
  ...
}: {
  wayland.windowManager.hyprland.settings = {
    exec-once = [
      "swww-daemon"
      "sleep 1 && theme-switch random"
      "hyprsunset"
      "systemctl --user start hyprpolkitagent"
      "wl-paste --type text --watch cliphist store"
      "wl-paste --type image --watch cliphist store"
      "xwaylandvideobridge"
      "1password --silent"
    ];

    exec = [
      "pkill -SIGUSR2 waybar || waybar"
    ];
  };
}
