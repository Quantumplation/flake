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
    '') themeNames)
    + ''
      echo "${builtins.concatStringsSep "\n" themeNames}" > $out/themes.list
    ''
  );
in {
  xdg.configFile."theme-data".source = themeDataDrv;
}
