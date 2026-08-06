{
  config,
  pkgs,
  ...
}: {
  programs.ghostty = {
    enable = true;
    enableFishIntegration = true;
    # Install the systemd user service + D-Bus activation (defaults to true on
    # Linux, set explicitly for clarity). See https://ghostty.org/docs/linux/systemd
    systemd.enable = true;
    settings = {
      # Window settings
      window-padding-x = 14;
      window-padding-y = 14;
      background-opacity = 0.95;
      window-decoration = "none";

      font-family = "CaskaydiaMono Nerd Font";
      font-size = 12;

      cursor-style = "block";
      cursor-style-blink = false;
      mouse-hide-while-typing = true;
      window-padding-balance = true;

      shell-integration-features = "sudo";

      # Connect to the running systemd/D-Bus daemon instead of spawning a fresh
      # process. Without this, `exec ghostty` keybinds bypass the daemon (the
      # "desktop" default only single-instances when launched from a .desktop
      # file). New windows go from ~300ms to ~20ms.
      gtk-single-instance = true;

      config-file = "/home/pi/.config/ghostty/theme-colors";
      keybind = [
        "ctrl+k=reset"
      ];
    };
  };

  # Start the daemon at login so even the first window is instant (the home-manager
  # ghostty module installs the unit but doesn't enable it). This is the
  # declarative equivalent of `systemctl --user enable app-com.mitchellh.ghostty`.
  # The unit's [Install] section is WantedBy=graphical-session.target.
  xdg.configFile."systemd/user/graphical-session.target.wants/app-com.mitchellh.ghostty.service".source =
    "${config.programs.ghostty.package}/share/systemd/user/app-com.mitchellh.ghostty.service";
}
