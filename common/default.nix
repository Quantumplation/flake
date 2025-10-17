{ config, pkgs, lib, inputs, ... }:

{
  imports = [
    ../packages/sops.nix
    ../packages/discord.nix
    (import ../packages/hyprland/system.nix inputs)
    ../modules/development.nix
    ../modules/desktop-utils.nix
    ../modules/fonts.nix
    ../modules/nix-settings.nix
    ../modules/audio.nix
    ../modules/users.nix
    ../modules/programs.nix
    (import ../home.nix inputs)
  ];

  nixpkgs.config.allowUnfree = true;

  boot = {
    kernelParams = [
      "quiet" "splash" "udev.log_priority=3"
      "boot.shell_on_fail"
    ];
    supportedFilesystems = [ "ntfs" ];
    loader.systemd-boot.enable = true;
    loader.efi.canTouchEfiVariables = true;
  };

  systemd.settings.Manager = {
    DefaultTimeoutStopSec = "30s";
  };

  networking.networkmanager.enable = true;
  networking.extraHosts = "";

  time.timeZone = "America/New_York";

  console = {
    earlySetup = true;
    useXkbConfig = true; # Use X keyboard config in console
  };

  # Enable numlock on boot
  systemd.services.numLockOnTty = {
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.kbd}/bin/setleds -D +num";
      StandardInput = "tty";
      TTYPath = "/dev/tty1";
    };
  };

  services.greetd = {
    enable = true;
    settings.default_session.command = "${pkgs.tuigreet}/bin/tuigreet --time --cmd Hyprland";
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
