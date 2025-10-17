{
  config,
  pkgs,
  ...
}: {
  wayland.windowManager.hyprland.settings = {
    exec-once = [
      "hyprsunset"
      "systemctl --user start hyprpolkitagent"
      "wl-paste --type text --watch cliphist store"
      "wl-paste --type image --watch cliphist store"
      "xwaylandvideobridge"
    ];

    exec = [
      "pkill -SIGUSR2 waybar || waybar"
    ];
  };
}
