{ config, pkgs, lib, inputs, ... }:

{
  imports = [
    ../../common
    ./hardware-configuration.nix
    ./nvidia.nix
  ];

  # Host-specific configuration for Goldwasser (Desktop)
  networking.hostName = "Goldwasser";

  # Desktop RGB lighting control
  services.hardware.openrgb.enable = true;

  home-manager.users.pi = lib.mkMerge [
    {
      imports = [ ../../packages/snap-back ];

      # Multi-monitor NVIDIA wake workaround: monitors stay black on resume
      # unless DPMS is toggled a couple of times to force signal renegotiation.
      services.hypridle.settings.listener = lib.mkForce [
        {
          timeout = 300;
          on-timeout = "loginctl lock-session";
        }
        {
          timeout = 330;
          on-timeout = "hyprctl dispatch dpms off";
          on-resume = "sleep 1 && hyprctl dispatch dpms on && sleep 3 && hyprctl dispatch dpms off && sleep 3 && hyprctl dispatch dpms on";
        }
      ];

      wayland.windowManager.hyprland.settings = {
        # Dual monitor setup
        monitor = [
          "DP-2, preferred, 0x0, 1"
          "DP-3, preferred, 2560x0, 1"
        ];

        # Workspace assignments for dual monitors
        workspace = [
          "1, name:Browse, monitor:DP-2, default:true, persistent:true"
          "2, name:Chat, monitor:DP-2, persistent:true"
          "3, name:Code, monitor:DP-3, default:true, persistent:true"
          "4, name:Misc, monitor:DP-3, persistent:true"
        ];

        # Alt-tab cycles windows (desktop behavior)
        bind = [
          "ALT, Tab, cyclenext,"
          "ALT, Tab, bringactivetotop,"
          "ALT SHIFT, Tab, cyclenext, prev"
          "ALT SHIFT, Tab, bringactivetotop"
        ];
      };
    }
  ];

  # Boot splash theme
  boot.plymouth = {
    enable = true;
    theme = "rings";
    themePackages = [ (pkgs.adi1090x-plymouth-themes.override { selected_themes = [ "rings" ]; }) ];
  };
}
