{ config, pkgs, lib, inputs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ./packages/sops.nix
    ./packages/discord.nix
    (import ./packages/hyprland/system.nix inputs)
    ./modules/development.nix
    ./modules/desktop-utils.nix
    ./modules/fonts.nix
    ./modules/nix-settings.nix
    ./modules/audio.nix
    ./modules/users.nix
    ./modules/programs.nix
    (import ./home.nix inputs)
  ];

  nixpkgs.config.allowUnfree = true;

  boot = {
    kernelParams = [
      "quiet" "splash" "udev.log_priority=3"
      "boot.shell_on_fail"
      "nvidia-drm.modeset=1"
      "nvidia-drm.fbdev=1"
    ];
    kernelModules = [
      "nvidia" "nvidia_modeset" "nvidia_uvm" "nvidia_drm"
    ];
    supportedFilesystems = [ "ntfs" ];
    loader.systemd-boot.enable = true;
    loader.efi.canTouchEfiVariables = true;

    # Plymouth provides the boot splash screen
    plymouth.enable = true;
    plymouth.theme = "rings";
    plymouth.themePackages = [ (pkgs.adi1090x-plymouth-themes.override { selected_themes = [ "rings" ]; }) ];
  };

  systemd.settings.Manager = {
    DefaultTimeoutStopSec = "30s";
  };
  systemd.services.nvidia-persistenced = {
    enable = true;
    wantedBy = [ "multi-user.target" ];
  };

  networking.hostName = "Goldwasser";
  networking.networkmanager.enable = true;
  networking.extraHosts =
    ''
    '';

  time.timeZone = "America/New_York";

  console.earlySetup = true;

  # Lighting automation
  services.hardware.openrgb.enable = true;

  services.greetd = {
    enable = true;
    settings.default_session.command = "${pkgs.tuigreet}/bin/tuigreet --time --cmd Hyprland";
  };


  hardware.graphics.enable = true;

  # Uncommenting this prevents us from starting!
  services.xserver.videoDrivers = ["nvidia"];
  hardware.nvidia = {
    package = config.boot.kernelPackages.nvidiaPackages.stable;
    open = false;
    modesetting.enable = true;
    powerManagement.enable = false;
    powerManagement.finegrained = false;
    nvidiaPersistenced = true;
    nvidiaSettings = true;
  };

  environment = {
    variables = {
      TERMINAL = "alacritty";
      EDITOR = "vim";
      VISUAL = "vim";
    };
    systemPackages = with pkgs; [
      # Core system tools
      tailscale

      # CLI staple replacements
      fzf
      zoxide
      ripgrep
      eza
      fd
    ];
  };

  # Systemd services
  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
    };
  };

  system.stateVersion = "22.11"; # Don't update

  virtualisation.docker.enable = true;
}
