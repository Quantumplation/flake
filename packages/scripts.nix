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
  ];
}
