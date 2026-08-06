{
  inputs,
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
    package = inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.hyprland;
    configType = "hyprlang";
    plugins = [];

    settings = {
      "$terminal" = lib.mkDefault "ghostty";
      "$fileManager" = lib.mkDefault "nautilus --new-window";
      "$browser" = lib.mkDefault "brave";
      "$messenger" = lib.mkDefault "signal-desktop";
      # Monitor and workspace rules are configured per-host
      input.follow_mouse = 2;
      debug.disable_logs = false;
    };
  };

  services.hyprpolkitagent.enable = true;
}
