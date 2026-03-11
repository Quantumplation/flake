{ pkgs, ... }: {
  home.packages = with pkgs; [
    zed-editor
  ];

  xdg.configFile."zed/settings.json".text = builtins.toJSON {
    vim_mode = true;
    theme = {
      mode = "dark";
      dark = "Tokyo Night";
      light = "Tokyo Night Light";
    };
    project_panel = {
      dock = "right";
    };
  };
}
