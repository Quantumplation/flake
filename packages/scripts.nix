{ pkgs, ... }: {
  home.packages = with pkgs; [
    # Keylight control script
    (writeShellApplication {
      name = "keylight";
      runtimeInputs = [ curl jq ];
      text = builtins.readFile ../assets/scripts/keylight.sh;
    })

    # Audio device switching with notification support
    (writeShellApplication {
      name = "audio-switch";
      runtimeInputs = [ curl libnotify ];
      text = builtins.readFile ../assets/scripts/audio-switch.sh;
    })

    # Clipboard manager with history
    (writeShellApplication {
      name = "clipboard-manager";
      runtimeInputs = [ cliphist wofi wl-clipboard gnugrep libnotify coreutils wtype ];
      text = builtins.readFile ../assets/scripts/clipboard-manager.sh;
    })

    # Smart tab switcher (workspace vs window cycling based on fullscreen state)
    (writeShellApplication {
      name = "smart-tab";
      runtimeInputs = [ hyprland jq ];
      text = builtins.readFile ../assets/scripts/smart-tab.sh;
    })

    # Screenshot wrapper that saves to ~/Captures/{year}-{month}/
    (writeShellApplication {
      name = "screenshot";
      runtimeInputs = [ hyprshot coreutils ];
      text = builtins.readFile ../assets/scripts/screenshot.sh;
    })

    # Swap windows between workspaces
    (writeShellApplication {
      name = "swap-workspaces";
      runtimeInputs = [ hyprland jq wofi libnotify ];
      text = builtins.readFile ../assets/scripts/swap-workspaces.sh;
    })

    # Runtime theme switcher (random on login, manual via theme-switch <name>)
    (writeShellApplication {
      name = "theme-switch";
      runtimeInputs = [ coreutils hyprland swww libnotify procps swaynotificationcenter ];
      text = builtins.readFile ../assets/scripts/theme-switch.sh;
    })

    # Quake-style dropdown terminal toggle
    (writeShellApplication {
      name = "quake-terminal";
      runtimeInputs = [ hyprland jq ghostty ];
      text = builtins.readFile ../assets/scripts/quake-terminal.sh;
    })
  ];
}
