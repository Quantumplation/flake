{
  inputs,
  config,
  pkgs,
  lib,
  ...
}: let
  themes = import ../modules/themes.nix;
  palette = config.colorScheme.palette;
  convert = inputs.nix-colors.lib.conversions.hexToRGBString;
  backgroundRgb = "rgb(${convert ", " palette.base00})";
  backgroundRgba = "rgba(${convert ", " palette.base00}, 0.75)";
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
    # Was reading waybar-ada-cycle.sh — copy-paste bug, so clicking cycled
    # the display mode instead of opening the explorer.
    text = builtins.readFile ../assets/waybar/waybar-ada-click.sh;
  };
in {
  # Make waybar-ada available in PATH for host-specific overrides
  home.packages = [ waybar-ada waybar-ada-cycle waybar-ada-click ];

  home.file = {
    ".config/waybar/" = {
      source = ../assets/waybar;
      recursive = true;
    };
    # theme.css is managed at runtime by theme-switch, not by home-manager
  };

  # On rebuild: apply current theme's CSS, or default theme if no choice made yet
  home.activation.initWaybarTheme = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    THEME_DATA="$HOME/.config/theme-data"
    CURRENT="$HOME/.config/current-theme"
    TARGET="$HOME/.config/waybar/theme.css"
    if [ -f "$CURRENT" ]; then
      THEME=$(cat "$CURRENT")
    else
      THEME="${themes.selected}"
      echo "$THEME" > "$CURRENT"
    fi
    if [ -f "$THEME_DATA/$THEME/theme.css" ]; then
      $DRY_RUN_CMD cp --no-preserve=mode "$THEME_DATA/$THEME/theme.css" "$TARGET"
    fi
  '';

  # On rebuild: apply current theme's swaync CSS too
  home.activation.initSwayncTheme = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    THEME_DATA="$HOME/.config/theme-data"
    CURRENT="$HOME/.config/current-theme"
    TARGET="$HOME/.config/swaync/style.css"
    if [ -f "$CURRENT" ]; then
      THEME=$(cat "$CURRENT")
    else
      THEME="${themes.selected}"
    fi
    if [ -f "$THEME_DATA/$THEME/swaync.css" ]; then
      $DRY_RUN_CMD mkdir -p "$(dirname "$TARGET")"
      $DRY_RUN_CMD cp --no-preserve=mode "$THEME_DATA/$THEME/swaync.css" "$TARGET"
    fi
  '';

  # On rebuild: apply current theme's ghostty colors
  home.activation.initGhosttyTheme = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    THEME_DATA="$HOME/.config/theme-data"
    CURRENT="$HOME/.config/current-theme"
    TARGET="$HOME/.config/ghostty/theme-colors"
    if [ -f "$CURRENT" ]; then
      THEME=$(cat "$CURRENT")
    else
      THEME="${themes.selected}"
    fi
    if [ -f "$THEME_DATA/$THEME/ghostty.conf" ]; then
      $DRY_RUN_CMD mkdir -p "$(dirname "$TARGET")"
      $DRY_RUN_CMD cp --no-preserve=mode "$THEME_DATA/$THEME/ghostty.conf" "$TARGET"
    fi
  '';

  programs.waybar = {
    enable = true;
    settings = [
      {
        layer = "top";
        position = "top";
        spacing = 0;
        height = 32;
        margin-top = 6;
        margin-left = 6;
        margin-right = 6;
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
          "tray"
          "custom/clipboard"
          "custom/ada"
          "custom/keylight"
          "custom/claude"
          "custom/volume"
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
          format = "{:%I:%M %p}";
          format-alt = "{:%Y-%m-%d  %A}";
          tooltip = false;
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
          on-click = "clipboard-manager snippets";
          on-click-right = "clipboard-manager menu";
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

        "custom/claude" = {
          exec = "~/.config/waybar/waybar-claude.sh";
          return-type = "json";
          # instant updates come from the hook via signal 9; the slow poll
          # exists to prune sessions that died without a SessionEnd hook
          interval = 15;
          signal = 9;
          on-click = "claude-dropdown";
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
