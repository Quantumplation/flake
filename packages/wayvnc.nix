inputs: {
  config,
  pkgs,
  ...
}: {
  services.wayvnc = {
    enable = true;
    autoStart = true;

    settings = {
      address = "0.0.0.0";
      port = 5900;
      enable_auth = true;
      username = "pi";
    };
  };
  # wayvnc doesn't support a password file, and we can't interpolate it directly
  # and we don't want to commit out password to git; so we override the service
  # to load it from disk on startup
  systemd.user.services.wayvnc = {
    Service = {
      Environment = "WAYLAND_DISPLAY=wayland-1";
      ExecStartPre = let
        injectPassword = pkgs.writeShellScript "wayvnc-inject-password" ''
          CONFIG_DIR="''${XDG_CONFIG_HOME:-$HOME/.config}/wayvnc"
          mkdir -p "$CONFIG_DIR"

          # Append password to the generated config
          sed '/^password=/d' "$CONFIG_DIR/config" > "$CONFIG_DIR/config.tmp"
          echo "password=$(cat /run/secrets/wayvnc/password)" >> "$CONFIG_DIR/config.tmp"
          mv "$CONFIG_DIR/config.tmp" "$CONFIG_DIR/config"
          chmod 600 "$CONFIG_DIR/config"
        '';
      in "${injectPassword}";
    };
  };
}
