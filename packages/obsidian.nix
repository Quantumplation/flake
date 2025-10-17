{ pkgs, ... }: {
  home.packages = with pkgs; [
    obsidian
  ];

  # Obsidian config is typically managed within the app itself
  # But we can add vault locations or other settings here if needed
}
