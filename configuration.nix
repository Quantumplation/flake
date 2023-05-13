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
        sddm = {
          enable = true;
          theme = "abstract-dark";
        };
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
    extraGroups = [ "wheel" "audio" ]; # Enable ‘sudo’ for the user.
    initialPassword = "password";
    shell = pkgs.fish;
  };

  # Programs that aren't managed by homemanager
  programs.fish.enable = true;
  programs.light.enable = true;

  fonts.fonts = with pkgs; [
    material-icons
    font-awesome
    corefonts
    (nerdfonts.override {
      fonts = [
        "FiraCode" "DroidSansMono" "Iosevka" "JetBrainsMono"
      ];
    })
  ];

  environment = {
    variables = {
      TERMINAL = "alacritty";
      EDITOR = "vim";
      VISUAL = "vim";
    };
    systemPackages = let themes = pkgs.callPackage ./packages/sddm-theme.nix {}; in [
      pkgs.vim
      pkgs.wget
      pkgs.git
      pkgs.xclip
      pkgs.xdotool
      pkgs.xsecurelock
      pkgs.discord
      pkgs.baobab

      themes.sddm-abstract-dark
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

  nixpkgs.overlays = [
    (self: super: {
      discord = super.discord.overrideAttrs (
        _: { src = builtins.fetchTarball {
          url = "https://discord.com/api/download?platform=linux&format=tar.gz";
          # sha256 = "0000000000000000000000000000000000000000000000000000";
          sha256 = "0mr1az32rcfdnqh61jq7jil6ki1dpg7bdld88y2jjfl2bk14vq4s";
       }; }
      );
    })
  ];
}

