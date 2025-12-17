{ config, pkgs, lib, inputs, ... }:

{
  imports = [
    ../../common
    ./hardware-configuration.nix
  ];

  # Host-specific configuration for Noether (Framework 16 Laptop)
  networking.hostName = "Noether";

  # Framework 16 specific settings
  hardware.framework.enable = true;

  # Laptop power management
  services.power-profiles-daemon.enable = true;
  services.thermald.enable = true;

  # Touchpad support
  services.libinput.enable = true;

  # Boot splash theme
  boot.plymouth = {
    enable = true;
    theme = "rings";
    themePackages = [ (pkgs.adi1090x-plymouth-themes.override { selected_themes = [ "rings" ]; }) ];
  };
}
