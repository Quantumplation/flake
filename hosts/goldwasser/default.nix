{ config, pkgs, lib, inputs, ... }:

{
  imports = [
    ../../common
    ./hardware-configuration.nix
    ./nvidia.nix
  ];

  # Host-specific configuration for Goldwasser (Desktop)
  networking.hostName = "Goldwasser";

  # Desktop RGB lighting control
  services.hardware.openrgb.enable = true;

  # Boot splash theme
  boot.plymouth = {
    enable = true;
    theme = "rings";
    themePackages = [ (pkgs.adi1090x-plymouth-themes.override { selected_themes = [ "rings" ]; }) ];
  };
}
