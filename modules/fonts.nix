{ pkgs, ... }: {
  fonts.packages = with pkgs; [
    material-icons
    font-awesome
    corefonts
    nerd-fonts.fira-code
    nerd-fonts.droid-sans-mono
    nerd-fonts.iosevka
    nerd-fonts.jetbrains-mono
    noto-fonts
    noto-fonts-color-emoji
    nerd-fonts.caskaydia-mono
  ];
}
