inputs: {
  config,
  pkgs,
  lib,
  ...
}: let
  themes = import ../modules/themes.nix;
  themeNames = builtins.filter (n: n != "selected") (builtins.attrNames themes);
  convert = inputs.nix-colors.lib.conversions.hexToRGBString;

  getColorScheme = name:
    inputs.nix-colors.colorSchemes.${themes.${name}.base16-theme};

  mkThemeCss = name: let
    palette = (getColorScheme name).palette;
    bgRgb = "rgb(${convert ", " palette.base00})";
    bgRgba = "rgba(${convert ", " palette.base00}, 0.75)";
    fgRgb = "rgb(${convert ", " palette.base05})";
  in ''
    @define-color background ${bgRgb};
    @define-color background-transparent ${bgRgba};
    * { color: ${fgRgb}; }
    window#waybar { background-color: ${bgRgba}; }
  '';

  mkSwayncCss = name: let
    palette = (getColorScheme name).palette;
    bg = convert ", " palette.base00;
    bg1 = convert ", " palette.base01;
    bg2 = convert ", " palette.base02;
    muted = "#${palette.base03}";
    fg = "#${palette.base05}";
    accent = palette.base0D;
    accentRgb = convert ", " palette.base0D;
    red = palette.base08;
    redRgb = convert ", " palette.base08;
    cyan = convert ", " palette.base0C;
  in ''
    * {
      all: unset;
      font-family: "JetBrainsMono Nerd Font", monospace;
      font-size: 14px;
    }

    .control-center {
      background: rgba(${bg}, 0.95);
      border: 2px solid rgba(${accentRgb}, 0.4);
      border-radius: 12px;
      margin: 10px;
      padding: 10px;
    }

    .control-center-list {
      background: transparent;
    }

    .notification {
      background: rgba(${bg1}, 0.9);
      border: 1px solid rgba(${accentRgb}, 0.3);
      border-radius: 8px;
      margin: 6px 0;
      padding: 10px;
    }

    .notification-time {
      color: ${muted};
      font-size: 12px;
    }

    .notification:hover {
      background: rgba(${bg2}, 0.95);
      border-color: rgba(${accentRgb}, 0.6);
    }

    .notification-content {
      padding: 8px;
    }

    .notification-default-action,
    .notification-action {
      background: rgba(${accentRgb}, 0.15);
      border: 1px solid rgba(${accentRgb}, 0.4);
      border-radius: 6px;
      padding: 8px 16px;
      color: #${accent};
      margin: 4px;
    }

    .notification-default-action:hover,
    .notification-action:hover {
      background: rgba(${accentRgb}, 0.25);
      border-color: rgba(${accentRgb}, 0.6);
    }

    .notification-default-action button,
    .notification-action button {
      background: transparent;
      color: #${accent};
    }

    .summary {
      color: #${accent};
      font-weight: bold;
    }

    .body {
      color: ${fg};
      margin-top: 4px;
    }

    .control-center-clear-all {
      background: rgba(${accentRgb}, 0.2);
      border: 1px solid rgba(${accentRgb}, 0.4);
      border-radius: 6px;
      color: #${accent};
      margin: 6px;
      padding: 8px;
    }

    .control-center-clear-all:hover {
      background: rgba(${accentRgb}, 0.3);
      border-color: rgba(${accentRgb}, 0.6);
    }

    .close-button {
      background: transparent;
      color: #${red};
      border-radius: 4px;
      padding: 4px;
    }

    .close-button:hover {
      background: rgba(${redRgb}, 0.2);
    }

    .notification-window {
      background: rgba(${bg}, 0.95);
      border: 2px solid rgba(${accentRgb}, 0.4);
      border-radius: 8px;
    }

    .low {
      border-left: 3px solid rgba(${cyan}, 0.6);
    }

    .normal {
      border-left: 3px solid rgba(${accentRgb}, 0.6);
    }

    .critical {
      border-left: 3px solid rgba(${redRgb}, 0.8);
      animation: blink 1s ease infinite;
    }

    .widget-dnd {
      background: transparent;
      padding: 8px 10px;
      margin: 5px 10px;
    }

    .widget-dnd > label {
      color: ${fg};
      font-size: 14px;
    }

    switch.control-center-dnd {
      background: rgba(${bg2}, 0.8);
      border: 1px solid rgba(${accentRgb}, 0.3);
      border-radius: 12px;
      min-width: 42px;
      min-height: 22px;
    }

    switch.control-center-dnd:checked {
      background: rgba(${accentRgb}, 0.4);
      border-color: rgba(${accentRgb}, 0.6);
    }

    switch.control-center-dnd slider {
      background: #${accent};
      border-radius: 50%;
      min-width: 16px;
      min-height: 16px;
      margin: 3px;
    }

    @keyframes blink {
      0%, 100% { opacity: 1; }
      50% { opacity: 0.8; }
    }
  '';

  mkBordersSh = name: let
    palette = (getColorScheme name).palette;
    active1 = "rgba(${palette.base0D}aa)";
    active2 = "rgba(${palette.base0E}aa)";
    inactive = "rgba(${palette.base09}aa)";
  in ''
    #!/usr/bin/env bash
    hyprctl keyword general:col.active_border "${active1} ${active2} 45deg"
    hyprctl keyword general:col.inactive_border "${inactive}"
  '';

  wallpaperDir = "${config.home.homeDirectory}/Pictures/Wallpapers";
  mkWallpaperPath = name: "${wallpaperDir}/${themes.${name}.wallpaper}";

  themeDataDrv = pkgs.runCommand "theme-data" {} (
    ''
      mkdir -p $out
    ''
    + builtins.concatStringsSep "\n" (map (name: ''
      mkdir -p $out/${name}
      cat > $out/${name}/theme.css << 'THEME_CSS_EOF'
      ${mkThemeCss name}
      THEME_CSS_EOF
      cat > $out/${name}/borders.sh << 'BORDERS_EOF'
      ${mkBordersSh name}
      BORDERS_EOF
      chmod +x $out/${name}/borders.sh
      echo "${mkWallpaperPath name}" > $out/${name}/wallpaper
      cat > $out/${name}/swaync.css << 'SWAYNC_CSS_EOF'
      ${mkSwayncCss name}
      SWAYNC_CSS_EOF
    '') themeNames)
    + ''
      echo "${builtins.concatStringsSep "\n" themeNames}" > $out/themes.list
    ''
  );
in {
  xdg.configFile."theme-data".source = themeDataDrv;
}
