{ config, pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ./home.nix
  ];

  nixpkgs.config.allowUnfree = true;

  boot = {
    kernelParams = ["quiet" "splash"];
    loader.systemd-boot.enable = true;
    loader.efi.canTouchEfiVariables = true;
    plymouth.enable = true;
    plymouth.theme = "connect";
    plymouth.themePackages = [ (pkgs.adi1090x-plymouth-themes.override { selected_themes = [ "connect" ]; }) ];
    initrd.kernelModules = [ "amdgpu" ];
  };
  systemd.extraConfig = ''
    DefaultTimeoutStopSec=30s
  '';

  networking.hostName = "pinix";
  networking.networkmanager.enable = true;

  time.timeZone = "America/New_York";

  console.earlySetup = true;
  services = {
    xserver = {
      enable = true;
      displayManager = {
        lightdm.enable = true;
        defaultSession = "xfce+bspwm";
      };
      desktopManager.xfce.enable = true;
      windowManager.bspwm = {
        enable = true;
      };
    };
  };

  sound.enable = true;
  hardware.pulseaudio.enable = true;

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.pi = {
    isNormalUser = true;
    extraGroups = [ "wheel" ]; # Enable ‘sudo’ for the user.
    initialPassword = "password";
    shell = pkgs.fish;
  };
  programs.fish.enable = true;

  fonts.fonts = with pkgs; [
    font-awesome
    corefonts
    (nerdfonts.override {
      fonts = [
        "FiraCode" "DroidSansMono"
      ];
    })
  ];

  environment = {
    variables = {
      TERMINAL = "alacritty";
      EDITOR = "vim";
      VISUAL = "vim";
    };
    systemPackages = with pkgs; [
      vim
      wget
      git
    ];
  };

  system.stateVersion = "22.11"; # Don't update

  nix = {
    package = pkgs.nixFlakes;
    extraOptions = "experimental-features = nix-command flakes";
    settings.auto-optimise-store = true;
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 7d";
    };
  };

}

