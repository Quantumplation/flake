{ pkgs, ... }: {
  home.packages = with pkgs; [
    zed-editor
  ];

  # Future: Add zed configuration here when needed
  # home.file.".config/zed/settings.json" = { ... };
}
