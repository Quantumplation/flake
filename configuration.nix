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
      windowManager.bspwm = {
        enable = true;
      };
      desktopManager.xfce.enable = true;
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
    openssh.authorizedKeys.keys = [
      "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCyexXui4Jvxh85549AtNVyUfYrj+esUZkT0a6XKnCeUaMbWmQpA1K0gGfZ9GXTCc8WhpkeizRQbUX42d2NYp7KUzRCB6wcrTwNMfr2yGtg6eyvkF3xfGB8Zlv9lCJ77TQuCS7gJnxMuao4f9KlpSFdUnt/ljjMXBFCkXE0p91cHaDgf9tHnQDnb4pRV7QL7xGw4HqQDnD0GbjcHIKh77yIF01lE3/N4eL/AGoDmRB7W1n0Bq7gMLW3bJHSOv2weIuNUyPqZjy0yuqHZgS1HlbcYxmqRXOB23IWKliNokWtP7zj2rvmaq5asOeAZ3DdukWaMcb3/75Xam5MXYhyqwZ385ULXU3bp0Stj5KFlDHPy93KRVDq1xYRIqok89KtNPvZhH8uR3nrLNB9LrC3w2A5KK3xCdKgcN+V7PHPLY5J6BhMbJaaH7rid/eMADM/RhGpxeogNzvbpI3px2lgtCXgqTDRsXzE6pOw4uKfOLjBWOSBNtWM2oNqmMUhcqSOQzM= pi"
    ];
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
      pkgs.tailscale
      pkgs.rustup
      pkgs.xpra
      pkgs.python3
      pkgs.signal-desktop-beta

      themes.sddm-abstract-dark
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
  services.tailscale.enable = true;

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

