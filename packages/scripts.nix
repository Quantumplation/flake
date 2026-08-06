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

    # Screenshot: slurp (drag-select) -> grim (capture) -> swappy (annotate)
    (writeShellApplication {
      name = "screenshot";
      runtimeInputs = [ grim slurp swappy wl-clipboard coreutils ];
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
      runtimeInputs = [ coreutils hyprland awww libnotify procps swaynotificationcenter ];
      text = builtins.readFile ../assets/scripts/theme-switch.sh;
    })

    # Quake-style dropdown terminal toggle
    (writeShellApplication {
      name = "quake-terminal";
      runtimeInputs = [ hyprland jq ghostty ];
      text = builtins.readFile ../assets/scripts/quake-terminal.sh;
    })

    # Claude session dashboard
    (writeShellApplication {
      name = "claude-dashboard";
      runtimeInputs = [ hyprland jq procps ncurses coreutils ];
      text = builtins.readFile ../assets/scripts/claude-dashboard.sh;
    })

    # Claude dashboard launcher (waybar click handler)
    (writeShellApplication {
      name = "claude-dropdown";
      runtimeInputs = [ hyprland jq ghostty procps ];
      text = builtins.readFile ../assets/scripts/claude-dropdown.sh;
    })

    # Claude Code hook for session monitoring (window capture needs hyprctl)
    (writeShellApplication {
      name = "claude-session-hook";
      runtimeInputs = [ jq coreutils procps hyprland ];
      text = builtins.readFile ../assets/scripts/claude-hook.sh;
    })

    # Todo capture (zero-UI): highlighted text straight into the todo app via
    # the `todo` CLI (imperative: ~/.local/bin, built from ~/proj/todo), which
    # handles auth + offline queueing.
    (writeShellApplication {
      name = "todo-capture";
      runtimeInputs = [ wofi wl-clipboard libnotify coreutils gnused ];
      text = builtins.readFile ../assets/scripts/todo-capture.sh;
    })

    # Todo panel: toggles the floating Tauri panel (~/.local/bin/todo-panel,
    # built from ~/proj/todo/packages/panel), passing the primary selection as
    # prefill. --autostart launches the resident instance hidden at login.
    (writeShellApplication {
      name = "todo-panel-toggle";
      runtimeInputs = [ wl-clipboard coreutils libnotify ]; # libnotify: panel notifications
      text = ''
        # eframe dlopens wayland/xkbcommon/GL at runtime (NixOS has no global libs)
        export LD_LIBRARY_PATH=${lib.makeLibraryPath [ wayland libxkbcommon libGL ]}:''${LD_LIBRARY_PATH:-}
        export PATH="$HOME/.local/bin:$PATH"
        if [[ "''${1:-}" == "--autostart" ]]; then
          exec todo-panel --hidden
        fi
        sel="$(wl-paste --primary --no-newline 2>/dev/null | head -c 500 || true)"
        exec todo-panel --prefill "$sel"
      '';
    })

    # Wattson panel: toggles the floating power-history panel
    # (~/.local/bin/wattson-panel, built from ~/proj/wattson/packages/panel).
    # Same resident-instance mechanics as todo-panel-toggle above.
    (writeShellApplication {
      name = "wattson-toggle";
      runtimeInputs = [ coreutils libnotify ];
      text = ''
        # eframe dlopens wayland/xkbcommon/GL at runtime (NixOS has no global libs)
        export LD_LIBRARY_PATH=${lib.makeLibraryPath [ wayland libxkbcommon libGL ]}:''${LD_LIBRARY_PATH:-}
        export PATH="$HOME/.local/bin:$PATH"
        if ! command -v wattson-panel >/dev/null; then
          # not built on this machine (e.g. fresh host) — fail quietly on autostart
          [[ "''${1:-}" == "--autostart" ]] && exit 0
          notify-send "wattson" "wattson-panel not installed (build ~/proj/wattson)"
          exit 1
        fi
        if [[ "''${1:-}" == "--autostart" ]]; then
          exec wattson-panel --hidden
        fi
        exec wattson-panel
      '';
    })

    # Sandboxed build/dev shell. `sbx npm install` runs the install with a
    # scratch $HOME, so postinstall scripts and build.rs cannot read ~/.ssh,
    # ~/.npmrc, ~/.aws or reach the SSH agent. See assets/scripts/sbx.sh.
    (writeShellApplication {
      name = "sbx";
      runtimeInputs = [ bubblewrap coreutils git findutils bashInteractive ];
      text = builtins.readFile ../assets/scripts/sbx.sh;
    })

    # Sonos CLI — noson ships noson-cli under lib/noson/, expose on PATH
    (writeShellScriptBin "noson-cli" ''exec ${noson}/lib/noson/noson-cli "$@"'')
  ];

  # Annotator for the `screenshot` script above. early_exit makes swappy quit
  # immediately after Ctrl+C / Ctrl+S instead of sitting there waiting to be
  # dismissed separately.
  xdg.configFile."swappy/config".text = ''
    [Default]
    save_dir=$HOME/Captures
    save_filename_format=%Y-%m/%Y-%m-%d_%H-%M-%S.png
    early_exit=true
    show_panel=true
    line_size=4
    text_size=20
    paint_mode=arrow
  '';
}
