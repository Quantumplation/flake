{ config, lib, pkgs, ... }:

let
  # Your workspace configuration
  workspaceAssociations = {
    "1" = {
      apps = [ "brave-browser" "Brave-browser" ];
      monitor = "DP-2";
      icon = "🌐";
      name = "web";
      layout = null; # No automatic layout for browser
    };
    "2" = {
      apps = [ "discord" "signal" "Signal" ];
      monitor = "DP-2";
      icon = "💬";
      name = "chat";
      layout = {
        direction = "horizontal";
        # Order matters! First in list = first in layout
        order = [ "discord" "signal" ];
        splitratio = 1.0;
      };
    };
    "3" = {
      apps = [ "dev.zed.Zed" "Zed" "com.mitchellh.ghostty" "ghostty" ];
      monitor = "DP-3";
      icon = "💻";
      name = "code";
      layout = {
        direction = "vertical";
        order = [ "dev.zed.Zed" "com.mitchellh.ghostty" ];
        splitratio = 1.2;
      };
    };
    "4" = {
      apps = [];
      monitor = "DP-3";
      icon = "🎵";
      name = "overflow";
      layout = null;
    };
  };

  # Generate bash associative array for workspace mappings
  generateWorkspaceMap = config:
    lib.concatStringsSep "\n" (
      lib.flatten (
        lib.mapAttrsToList (workspace: wsConfig:
          map (app: ''WORKSPACE_MAP["${app}"]="${workspace}"'') wsConfig.apps
        ) config
      )
    );

  # Generate bash associative array for layout configurations
  generateLayoutConfig = config:
    lib.concatStringsSep "\n" (
      lib.mapAttrsToList (workspace: wsConfig:
        if wsConfig.layout != null then
          ''LAYOUT_CONFIG["${workspace}"]='${builtins.toJSON wsConfig.layout}' ''
        else
          ""
      ) config
    );

  # Main snap-back script
  snapBackScript = pkgs.writeShellScriptBin "hypr-snap-back" ''
    PATH=${pkgs.bc}/bin:${pkgs.jq}/bin:${pkgs.hyprland}/bin:$PATH

    ${builtins.readFile ./hypr-snap-back.sh}

    # Workspace associations (injected from Nix)
    declare -A WORKSPACE_MAP
    ${generateWorkspaceMap workspaceAssociations}

    # Layout configurations (injected from Nix)
    declare -A LAYOUT_CONFIG
    ${generateLayoutConfig workspaceAssociations}

    # Run main function
    main
  '';

  # Count misplaced windows script
  countMisplacedScript = pkgs.writeShellScriptBin "hypr-count-misplaced" ''
    ${builtins.readFile ./hypr-count-misplaced.sh}

    # Workspace associations (injected from Nix)
    declare -A WORKSPACE_MAP
    ${generateWorkspaceMap workspaceAssociations}

    # Layout configurations (injected from Nix)
    declare -A LAYOUT_CONFIG
    ${generateLayoutConfig workspaceAssociations}

    # Run count function
    count_misplaced
  '';

  # Generate Hyprland window rules
  generateWindowRules = config:
    lib.flatten (
      lib.mapAttrsToList (workspace: wsConfig:
        map (app:
          # Use windowrulev2 for better matching
          "workspace ${workspace} silent, match:class ^(${app})$"
        ) wsConfig.apps
      ) config
    );

in {
  # Install scripts
  home.packages = [
    snapBackScript
    countMisplacedScript
  ];

  # Generate Hyprland config
  wayland.windowManager.hyprland.settings = {
    # Window rules - auto-assign workspaces
    windowrule = generateWindowRules workspaceAssociations;

    # Keybindings
    bind = [
      # Snap back shortcut
      "SUPER, S, exec, hypr-snap-back"
    ];
  };
}
