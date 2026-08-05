{ config, pkgs, lib, inputs, ... }:

{
  imports = [
    ../../common
    ./hardware-configuration.nix
    inputs.nixos-hardware.nixosModules.framework-16-amd-ai-300-series-nvidia
  ];

  # Host-specific configuration for Noether (Framework 16 Laptop)
  networking.hostName = "Noether";

  # VA-API: use AMD iGPU for hardware video decode (not the NVIDIA dGPU)
  environment.variables.LIBVA_DRIVER_NAME = "radeonsi";

  # Enable sound
  environment.variables.ALSA_CONFIG_UCM2_DIR = "${pkgs.alsa-ucm-conf}/share/alsa/ucm2";
  environment.systemPackages = [
    pkgs.alsa-ucm-conf
    pkgs.easyeffects
    pkgs.inputmodule-control  # Framework RGB keyboard/LED matrix control
  ];

  # NVIDIA power management - required for suspend/hibernate
  # The nixos-hardware module sets PreserveVideoMemoryAllocations but we need
  # the systemd services (nvidia-suspend, nvidia-hibernate, nvidia-resume) enabled
  hardware.nvidia.powerManagement.enable = true;

  # Swap file for hibernation (32GB to cover hibernate image)
  # zram disabled - causes "inconsistent memory map" errors during hibernate resume
  # (also unnecessary with 96GB RAM)

  swapDevices = [{
    device = "/var/lib/swapfile";
    size = 32 * 1024;  # 32GB - should cover RAM for hibernate
  }];

  # Hibernation support
  boot.resumeDevice = "/dev/mapper/cryptroot";
  boot.kernelParams = [
    "resume=/dev/mapper/cryptroot"
    "resume_offset=19226624"
    "hibernate=noerrors"  # Relax memory map validation - AMD laptops have inconsistent maps between boots
  ];

  # Low battery warning and hibernate
  # Thresholds raised for safety - hibernate needs time and power to complete
  services.upower = {
    enable = true;
    percentageLow = 20;
    percentageCritical = 15;
    percentageAction = 10;  # Was 5% - too risky, hibernate might not complete
    criticalPowerAction = "Hibernate";
  };

  # Suspend-then-hibernate: if suspended for 30min, automatically hibernate
  # This prevents battery death during extended suspend
  systemd.sleep.extraConfig = ''
    HibernateDelaySec=30min
  '';

  # Emergency failsafe: force hibernate at 8% regardless of UPower
  # Runs as root, checks every 30 seconds when below 15%
  systemd.services.battery-hibernate-failsafe = {
    description = "Emergency battery hibernate failsafe";
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "simple";
      Restart = "always";
      RestartSec = 30;
    };
    script = ''
      while true; do
        if [[ -f /sys/class/power_supply/BAT1/capacity ]]; then
          capacity=$(cat /sys/class/power_supply/BAT1/capacity)
          status=$(cat /sys/class/power_supply/BAT1/status)
          if [[ "$status" == "Discharging" && $capacity -le 8 ]]; then
            echo "EMERGENCY: Battery at $capacity%, forcing hibernate"
            systemctl hibernate
          fi
        fi
        sleep 30
      done
    '';
  };

  # Ensure logind uses suspend-then-hibernate for safety
  # After HibernateDelaySec (30min), suspended system will auto-hibernate
  services.logind.settings.Login = {
    HandleLidSwitch = "suspend-then-hibernate";
    HandleLidSwitchExternalPower = "lock";
    HandlePowerKey = "suspend-then-hibernate";
    HandlePowerKeyLongPress = "poweroff";
    IdleAction = "suspend-then-hibernate";
    IdleActionSec = "15min";
  }; 

  # Laptop power management
  services.power-profiles-daemon.enable = true;
  services.thermald.enable = true;

  # Wattson: power-history sampler (RAPL + battery + per-app CPU → SQLite,
  # API on 127.0.0.1:4713). The panel is toggled from the waybar battery
  # icon. Inlined copy of ~/proj/wattson/nix/module.nix — flake purity
  # forbids importing module files from outside this repo; keep in sync.
  # Root because RAPL counters are 0400 root (PLATYPUS mitigation); code
  # runs from the checked-out repo, so changes need only a service restart.
  systemd.services.wattson = {
    description = "wattson power-history sampler";
    wantedBy = [ "multi-user.target" ];
    after = [ "local-fs.target" ];
    environment = {
      WATTSON_DB = "/var/lib/wattson/wattson.db";
      WATTSON_PORT = "4713";
      WATTSON_INTERVAL_MS = "10000";
    };
    serviceConfig = {
      ExecStart = "${pkgs.bun}/bin/bun /home/pi/proj/wattson/packages/daemon/src/index.ts";
      WorkingDirectory = "/home/pi/proj/wattson";
      StateDirectory = "wattson";
      Restart = "on-failure";
      RestartSec = 5;
      ProtectSystem = "strict";
      ProtectHome = "read-only"; # bun reads the repo out of /home
      ReadWritePaths = [ "/var/lib/wattson" ];
      PrivateTmp = true;
      NoNewPrivileges = true;
      # DAC_READ_SEARCH: /home/pi is 0700, so even root needs this to
      # traverse into the repo (dropping ALL caps → CouldntReadCurrentDirectory)
      CapabilityBoundingSet = [ "CAP_DAC_READ_SEARCH" ];
      RestrictAddressFamilies = [ "AF_INET" "AF_UNIX" ];
      MemoryMax = "512M";
      CPUWeight = 20; # never compete with real work
    };
  };

  # Touchpad support
  services.libinput = {
    enable = true;
    touchpad = {
      # Use adaptive acceleration for smoother, more natural scrolling
      accelProfile = "adaptive";
      # Slightly reduce acceleration speed (-1 to 1, negative = slower)
      accelSpeed = "-0.3";
    };
  };

  home-manager.users.pi = lib.mkMerge [
    {
      # Battery notification script
      home.packages = [
        (pkgs.writeShellApplication {
          name = "battery-notify";
          runtimeInputs = [ pkgs.libnotify ];
          text = builtins.readFile ../../assets/scripts/battery-notify.sh;
        })
      ];

      # Battery monitoring service
      systemd.user.services.battery-notify = {
        Unit = {
          Description = "Battery level notification daemon";
          After = [ "graphical-session.target" ];
          PartOf = [ "graphical-session.target" ];
        };
        Service = {
          ExecStart = "${pkgs.writeShellApplication {
            name = "battery-notify";
            runtimeInputs = [ pkgs.libnotify ];
            text = builtins.readFile ../../assets/scripts/battery-notify.sh;
          }}/bin/battery-notify";
          Restart = "always";
          RestartSec = 5;
        };
        Install.WantedBy = [ "graphical-session.target" ];
      };

      # Override waybar modules for laptop (remove snapback, add battery)
      programs.waybar.settings = lib.mkForce [{
        layer = "top";
        position = "top";
        spacing = 0;
        height = 32;
        margin-top = 4;
        margin-left = 4;
        margin-right = 4;
        modules-left = [
          "hyprland/workspaces"
          "custom/separator"
          "hyprland/window"
        ];
        modules-center = [ "clock" ];
        modules-right = [
          "battery"
          "custom/brightness"
          "custom/separator"
          "tray"
          "custom/clipboard"
          "custom/ada"
          "custom/claude"
          "custom/volume"
          "custom/swaync"
        ];

        "hyprland/workspaces" = {
          on-click = "activate";
          format = "{windows}";
          format-window-separator = " ";
          window-rewrite-default = "?";
          window-rewrite = {
            "brave-browser" = "";
            "firefox" = "";
            "chromium" = "";
            "com.mitchellh.ghostty" = "";
            "Alacritty" = "";
            "kitty" = "";
            "code" = "󰨞";
            "Code" = "󰨞";
            "Zed" = "";
            "zed" = "";
            "Signal" = "󰭹";
            "discord" = "󰙯";
            "org.gnome.Nautilus" = "󰉋";
            "thunar" = "󰉋";
          };
          all-outputs = false;
        };

        "hyprland/window" = {
          format = "{title}";
          icon = true;
          icon-size = 24;
          max-length = 50;
          separate-outputs = true;
          rewrite."" = " Desktop";
        };

        clock = {
          format = "{:%I:%M %p}";
          format-alt = "{:%Y-%m-%d  %A}";
          tooltip = false;
        };

        battery = {
          format = "{icon} {capacity}%";
          format-icons = [ "󰁺" "󰁻" "󰁼" "󰁽" "󰁾" "󰁿" "󰂀" "󰂁" "󰂂" "󰁹" ];
          format-charging = "󰂄 {capacity}%";
          tooltip-format = "{timeTo}";
          on-click = "wattson-toggle"; # power history panel (~/proj/wattson)
        };

        "custom/brightness" = {
          exec = "~/.config/waybar/waybar-brightness.sh";
          return-type = "json";
          interval = 1;
          smooth-scrolling-threshold = 5;
          on-scroll-up = "brightnessctl set 5%+";
          on-scroll-down = "brightnessctl set 5%-";
          on-click = "brightnessctl set 100%";
          on-click-right = "brightnessctl set 50%";
        };

        "custom/separator".format = "|";
        "custom/clipboard" = {
          exec = "~/.config/waybar/waybar-clipboard.sh";
          format = "📋";
          interval = 5;
          on-click = "clipboard-manager snippets";
          on-click-right = "clipboard-manager menu";
          return-type = "json";
        };
        "custom/volume" = {
          exec = "~/.config/waybar/waybar-volume.sh";
          return-type = "json";
          interval = 1;
          smooth-scrolling-threshold = 5;
          on-click = "audio-switch wofi";
          on-click-right = "wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle";
          on-scroll-up = "wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+";
          on-scroll-down = "wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-";
        };
        "custom/claude" = {
          exec = "~/.config/waybar/waybar-claude.sh";
          return-type = "json";
          interval = 5;
          on-click = "claude-dropdown";
        };
        "custom/ada" = {
          exec = "waybar-ada";
          return-type = "json";
          interval = 60;
          signal = 8;
        };
        "custom/swaync" = {
          format = "{icon}";
          format-icons = {
            notification = "󰂚";
            none = "󰂛";
            dnd-notification = "󰂛";
            dnd-none = "󰪑";
          };
          return-type = "json";
          exec-if = "which swaync-client";
          exec = "swaync-client -swb";
          on-click = "swaync-client -t -sw";
          on-click-right = "swaync-client -d -sw";
          escape = true;
        };
        tray.spacing = 13;
      }];

      wayland.windowManager.hyprland.settings = {
        # Tighter gaps for laptop screen real estate
        general = {
          gaps_in = lib.mkForce 2;
          gaps_out = lib.mkForce 4;
        };

        input.touchpad = {
          natural_scroll = true;
          # Reduce scroll speed (default is 1.0, lower = slower)
          scroll_factor = 0.5;
        };

        # 3-finger swipe to switch workspaces (laptop-specific)
        gestures = {
          gesture = "3, horizontal, workspace";
          workspace_swipe_distance = 150;  # lower = more sensitive (default 300)
          workspace_swipe_invert = true;  # left = next, right = prev
          workspace_swipe_create_new = false;
        };

        # Smoother workspace switch animation for gestures
        animations.animation = [
          "workspaces, 1, 5, default, slide"  # enabled, speed (higher=slower), curve, style
        ];

        # Smart tab: cycles workspaces normally, cycles windows when fullscreen
        bind = [
          "ALT, Tab, exec, smart-tab next"
          "ALT SHIFT, Tab, exec, smart-tab prev"

          # Switch to specific workspaces
          "SUPER, 1, workspace, 1"
          "SUPER, 2, workspace, 2"
          "SUPER, 3, workspace, 3"
          "SUPER, 4, workspace, 4"
          "SUPER, 5, workspace, 5"

          # Move window to specific workspace
          "SUPER SHIFT, 1, movetoworkspace, 1"
          "SUPER SHIFT, 2, movetoworkspace, 2"
          "SUPER SHIFT, 3, movetoworkspace, 3"
          "SUPER SHIFT, 4, movetoworkspace, 4"
          "SUPER SHIFT, 5, movetoworkspace, 5"

          # Create new workspace and switch to it
          "SUPER, N, exec, hyprctl dispatch workspace empty"
        ];

        # Open new windows on the workspace where they were invoked
        misc.initial_workspace_tracking = 2;
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
