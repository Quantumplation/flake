inputs: {
  config,
  pkgs,
  ...
}: {
  imports = [
    inputs.hyprshell.homeModules.hyprshell
  ];
  programs.hyprshell = {
    enable = true;
    hyprland = inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.default;
    systemd.args = "-v";
    settings = {
      windows = {
        enable = true;
        overview = {
          enable = true;
          key = "super_l";
          modifier = "super";
          launcher = {
            default_terminal = "ghostty";
            max_items = 5;
          };
        };
        switch.enable = true;
      };
    };
  };
}
