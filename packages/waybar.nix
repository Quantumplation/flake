inputs: {
  config,
  pkgs,
  ...
}: let
  palette = config.colorScheme.palette;
  convert = inputs.nix-colors.lib.conversions.hexToRGBString;
  backgroundRgb = "rgb(${convert ", " palette.base00})";
  foregroundRgb = "rgb(${convert ", " palette.base05})";
  waybar-ada = pkgs.writeShellApplication {
    name = "waybar-ada";
    runtimeInputs = with pkgs; [ curl gnugrep coreutils bc gnused libnotify gawk ];
    text = ''
      # Injected paths
      BLOCKFROST_KEY_FILE="/run/secrets/blockfrost/mainnet" # TODO: sops injection
      MERCURY_KEY_FILE="/run/secrets/mercury/apiKey" # TODO: sops injection
      ADDRESSES_FILE="${../assets/waybar/waybar-ada-addresses.conf}"
      ${builtins.readFile ../assets/waybar/waybar-ada.sh}
    '';
  };
  waybar-ada-cycle = pkgs.writeShellApplication {
    name = "waybar-ada-cycle";
    runtimeInputs = [ pkgs.procps ];
    text = builtins.readFile ../assets/waybar/waybar-ada-cycle.sh;
  };
  waybar-ada-click = pkgs.writeShellApplication {
    name = "waybar-ada-click";
    runtimeInputs = [ pkgs.xdg-utils ];
    text = builtins.readFile ../assets/waybar/waybar-ada-cycle.sh;
  };
in {
  home.file = {
    ".config/waybar/" = {
      source = ../assets/waybar;
      recursive = true;
    };
    ".config/waybar/theme.css" = {
      text = ''
        @define-color background ${backgroundRgb};
        * {
          color: ${foregroundRgb};
        }

        window#waybar {
          background-color: ${backgroundRgb};
        }
      '';
    };
  };

  programs.waybar = {
    enable = true;
    settings = [
      {
        layer = "top";
        position = "top";
        spacing = 0;
        height = 26;
        modules-left = [
          "custom/snapback"
          "custom/separator"
          "hyprland/workspaces"
          "custom/separator"
          "hyprland/window"
        ];
        modules-center = [
          "clock"
        ];
        modules-right = [
          "custom/github"
          "tray"
          "custom/clipboard"
          "custom/ada"
          "custom/keylight"
          "custom/volume"
          "custom/system"
          "custom/swaync"
        ];

        "hyprland/workspaces" = {
          on-click = "activate";
          format = "{icon}";
          tooltip-format = "{name}";
          format-icons = {
            default = "?";
            "1" = "";
            "2" = "󰭹";
            "3" = "";
            "4" = "󰉋";
          };
          all-outputs = false;
        };

        "hyprland/window" = {
          format = "{title}";
          icon = true;
          icon-size = 24;
          max-length = 50;
          separate-outputs = true;
          rewrite = {
            # "(.*) — Brave" = "󰊯 $1";
            # "(.*) - Visual Studio Code" = "󰨞 $1";
            # "(.*) - Zed" = "$1";
            # "(.*) - Discord" = " $1";
            # "ghostty" = " Terminal";
            # "(.*)ghostty" = " $1";
            "" = " Desktop";
          };
        };

        cpu = {
          interval = 5;
          format = "󰍛";
          on-click = "ghostty -e btop";
        };

        clock = {
          format = "{:%Y-%m-%d %I:%M %p}";
          format-alt = "{%A, %B %d, %Y}";
          tooltip = false;
        };

        "custom/github" = {
          exec = "~/.config/waybar/waybar-github.sh";
          return-type = "json";
          interval = 30;
          on-click = "xdg-open https://github.com/notifications";
          format = "{}";
        };

        "custom/separator" = {
          format = "|";
          tooltip = false;
        };

        "custom/clipboard" = {
          exec = "~/.config/waybar/waybar-clipboard.sh";
          format = "📋";
          tooltip = true;
          interval = 5;
          on-click = "clipboard-manager menu";
          on-click-right = "clipboard-manager snippets";
          return-type = "json";
        };

        "custom/snapback" = {
          exec = "hypr-count-misplaced";
          interval = 5;
          return-type = "json";
          format = "{icon} {text}";
          format-icons = {
            default = "󰁌";
            misplaced = "󰁍";
          };
          on-click = "hypr-snap-back && sleep 0.5 && pkill -RTMIN+8 waybar";
          signal = 8;
          tooltip = true;
        };

        "custom/volume" = {
          exec = "~/.config/waybar/waybar-volume.sh";
          return-type = "json";
          interval = 1;
          on-click = "audio-switch wofi";
          on-click-right = "wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle";
          on-click-middle = "pavucontrol";
          on-scroll-up = "wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+";
          on-scroll-down = "wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-";
          format = "{}";
        };

        "custom/keylight" = {
          exec = "~/.config/waybar/waybar-keylight.sh";
          return-type = "json";
          interval = 2;
          on-click = "keylight toggle";
          on-click-right = "keylight preset recording";
          on-scroll-up = "keylight brighter 5";
          on-scroll-down = "keylight dimmer 5";
          format = "{}";
        };

        "custom/system" = {
          exec = "~/.config/waybar/waybar-system.sh";
          return-type = "json";
          interval = 3;
          on-click = "ghostty -e btop";
          format = "{}";
        };

        "custom/ada" = {
          exec = "${waybar-ada}/bin/waybar-ada";
          return-type = "json";
          interval = 60;
          signal = 8;
          on-click = "${waybar-ada-click}/bin/waybar-ada-click";
          on-click-right = "${waybar-ada-cycle}/bin/waybar-ada-cycle";
          format = "{}";
        };

        "custom/swaync" = {
          format = "{icon}";
          format-icons = {
            notification = "󰂚";  # Bell with dot (notification indicator)
            none = "󰂛";  # Bell outline (no notifications)
            dnd-notification = "󰂛";  # Bell crossed out with notification
            dnd-none = "󰪑";  # Bell crossed out (DND)
          };
          return-type = "json";
          exec-if = "which swaync-client";
          exec = "swaync-client -swb";
          on-click = "swaync-client -t -sw";
          on-click-right = "swaync-client -d -sw";
          escape = true;
          tooltip = true;
        };

        tray = {
          spacing = 13;
        };

        power-profiles-daemon = {
          format = "{icon}";
          tooltip-format = "Power profile: {profile}";
          tooltip = true;
          format-icons = {
            power-saver = "󰡳";
            balanced = "󰊚";
            performance = "󰡴";
          };
        };
      }
    ];
  };
}
