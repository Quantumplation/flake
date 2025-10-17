inputs: {
  config,
  pkgs,
  lib,
  ...
}: {
  imports = [
    ./autostart.nix
    ./bindings.nix
    ./envs.nix
    ./aesthetic.nix
    ./windows.nix
  ];

  wayland.windowManager.hyprland = {
    enable = true;
    package = inputs.hyprland.packages.${pkgs.system}.hyprland;
    plugins = [
      inputs.split-monitor-workspaces.packages.${pkgs.system}.split-monitor-workspaces
    ];

    settings = {
      "$terminal" = lib.mkDefault "ghostty";
      "$fileManager" = lib.mkDefault "nautilus --new-window";
      "$browser" = lib.mkDefault "brave";
      "$messenger" = lib.mkDefault "signal-desktop";
      monitor = [
        "DP-2, preferred, 0x0, 1"
        "DP-3, preferred, 2560x0, 1"
      ];
      # TODO: bake in defaults
      # https://deepwiki.com/hyprwm/hyprland-wiki/3.5-monitors-and-workspaces#workspace-rules
      workspace = [
        "1, name:Browse, monitor:DP-2, default:true, persistent:true"
        "2, name:Chat, monitor:DP-2, persistent:true"
        "3, name:Code, monitor:DP-3, default:true, persistent:true"
        "4, name:Misc, monitor:DP-3, persistent:true"
      ];
      input.follow_mouse = 2;
      debug.disable_logs = false;
      plugin = {
        split-monitor-workspaces = {
          count = 2;
          keep_focused = 1;
          enable_notifications = 0;
          enable_persistent_workspaces = 1;
        };
      };
    };
  };

  services.hyprpolkitagent.enable = true;
}
