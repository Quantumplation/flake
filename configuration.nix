{ config, pkgs, lib, aiken, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ./home.nix
  ];

  nixpkgs.config.allowUnfree = true;
  nixpkgs.config.permittedInsecurePackages = [
    "electron-25.9.0"
  ];

  boot = {
    kernelParams = ["quiet" "splash"];
    supportedFilesystems = [ "ntfs" ];
    loader.systemd-boot.enable = true;
    loader.efi.canTouchEfiVariables = true;
    plymouth.enable = true;
    plymouth.theme = "connect";
    plymouth.themePackages = [ (pkgs.adi1090x-plymouth-themes.override { selected_themes = [ "connect" ]; }) ];
  };
  systemd.extraConfig = ''
    DefaultTimeoutStopSec=30s
  '';

  networking.hostName = "Goldwasser";
  networking.networkmanager.enable = true;
  networking.extraHosts =
    ''
    '';

  time.timeZone = "America/New_York";

  console.earlySetup = true;
  services = {
    displayManager = {
      sddm = {
        enable = true;
        theme = "abstract-dark";
      };
      defaultSession = "xfce+bspwm";
    };
    xserver = {
      enable = true;
      videoDrivers = [ "nvidia" ];
      windowManager.bspwm = {
        enable = true;
      };
      desktopManager.xfce.enable = true;
      wacom.enable = true;
    };
  };

#   sops = {
#     defaultSopsFile = ./secrets/secrets.yaml;
#     defaultSopsFormat = "yaml";
#     age = {
#       sshKeyPaths = ["/home/pi/.ssh/id_ed25519"];
#       keyFile = "/home/pi/.config/sops/age/keys.txt";
#       generateKey = true;
#     };
#     secrets = {
#       "atuin/username" = {
#         mode = "0440";
#         owner = config.users.users.pi.name;
#       };
#       "atuin/password" = {
#         mode = "0440";
#         owner = config.users.users.pi.name;
#       };
#       "atuin/key" = {
#         mode = "0440";
#         owner = config.users.users.pi.name;
#       };
#     };
#   };


  #hardware.pulseaudio.enable = true;
  hardware.graphics.enable = true;
  hardware.nvidia.package = config.boot.kernelPackages.nvidiaPackages.stable;
  hardware.nvidia.open = true;
  hardware.nvidia.modesetting.enable = true;

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.pi = {
    isNormalUser = true;
    extraGroups = [ "wheel" "audio" "tty" "dialout" "docker" ]; # Enable ‘sudo’ for the user.
    initialPassword = "password";
    shell = pkgs.fish;
    openssh.authorizedKeys.keys = [
      "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQCyexXui4Jvxh85549AtNVyUfYrj+esUZkT0a6XKnCeUaMbWmQpA1K0gGfZ9GXTCc8WhpkeizRQbUX42d2NYp7KUzRCB6wcrTwNMfr2yGtg6eyvkF3xfGB8Zlv9lCJ77TQuCS7gJnxMuao4f9KlpSFdUnt/ljjMXBFCkXE0p91cHaDgf9tHnQDnb4pRV7QL7xGw4HqQDnD0GbjcHIKh77yIF01lE3/N4eL/AGoDmRB7W1n0Bq7gMLW3bJHSOv2weIuNUyPqZjy0yuqHZgS1HlbcYxmqRXOB23IWKliNokWtP7zj2rvmaq5asOeAZ3DdukWaMcb3/75Xam5MXYhyqwZ385ULXU3bp0Stj5KFlDHPy93KRVDq1xYRIqok89KtNPvZhH8uR3nrLNB9LrC3w2A5KK3xCdKgcN+V7PHPLY5J6BhMbJaaH7rid/eMADM/RhGpxeogNzvbpI3px2lgtCXgqTDRsXzE6pOw4uKfOLjBWOSBNtWM2oNqmMUhcqSOQzM= pi"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIJ/dREQHWeS7YuT3x8UK7jbgTLUFyJ84aeJrYootfYa quantumplation@QuantumtionsMBP.lan"
    ];
  };

  # Programs that aren't managed by homemanager
  programs.fish.enable = true;
  programs.light.enable = true;
  programs.ssh.startAgent = true;
  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true;
    dedicatedServer.openFirewall = true;
  };
  programs.gnupg = {
    agent.enable = true;
  };

  programs.nix-ld.enable = true;
  programs.nix-ld.libraries = with pkgs; [
    stdenv.cc.cc
    fuse3
    alsa-lib
    at-spi2-atk
    at-spi2-core
    atk
    cairo
    cups
    curl
    dbus
    expat
    fontconfig
    freetype
    gdk-pixbuf
    glib
    gtk3
    libGL
    libappindicator-gtk3
    libdrm
    libnotify
    libpulseaudio
    libuuid
    libusb1
    xorg.libxcb
    libxkbcommon
    mesa
    nspr
    nss
    pango
    systemd
    icu
    openssl
    xorg.libX11
    xorg.libXScrnSaver
    xorg.libXcomposite
    xorg.libXcursor
    xorg.libXdamage
    xorg.libXext
    xorg.libXfixes
    xorg.libXi
    xorg.libXrandr
    xorg.libXrender
    xorg.libXtst
    xorg.libxkbfile
    xorg.libxshmfence
    zlib
  ];

  fonts.packages = with pkgs; [
    material-icons
    font-awesome
    corefonts
    nerd-fonts.fira-code
    nerd-fonts.droid-sans-mono
    nerd-fonts.iosevka
    nerd-fonts.jetbrains-mono
  ];

  environment = {
    variables = {
      TERMINAL = "alacritty";
      EDITOR = "vim";
      VISUAL = "vim";
      TEST = "abc";
    };
    systemPackages = let themes = pkgs.callPackage ./packages/sddm-theme.nix {}; in [
      pkgs.vim_configurable
      pkgs.gcc
      pkgs.clang
      pkgs.glib
      pkgs.meld
      pkgs.wget
      pkgs.git
      pkgs.xclip
      pkgs.xdotool
      pkgs.xsecurelock
      pkgs.discord
      pkgs.baobab
      pkgs.tailscale
      pkgs.rustup
      pkgs.llvmPackages.libclang
      pkgs.llvmPackages.libcxxClang
      pkgs.clang
      pkgs.deno
      pkgs.xpra
      pkgs.python3
      pkgs.gotools
      pkgs.go-tools
      pkgs.gopls
      pkgs.delve
      pkgs.awscli2
      pkgs.aws-vault
      pkgs.brave
      pkgs.zip
      pkgs.unzip
      pkgs.mypaint
      pkgs.zig
      pkgs.cachix
      pkgs.obs-studio
      pkgs.inotify-tools
      pkgs.vlc
      pkgs.digikam
      pkgs.nodejs_20
      pkgs.arduino
      pkgs.jq
      pkgs.pkg-config
      pkgs.signal-desktop
      pkgs.typst
      pkgs.obsidian
      pkgs.pkg-config
      pkgs.openssl
      pkgs.btop
      pkgs.zed-editor
      pkgs.bun
      pkgs.libsoup_2_4
      pkgs.webkitgtk
      pkgs.gobject-introspection
      pkgs.buf
      pkgs.sops
      pkgs.kubectl
      pkgs.k9s
      pkgs.aws-vault
      pkgs.gnupg

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

  virtualisation.docker.enable = true;

  nix = {
    package = pkgs.nixVersions.stable;
    extraOptions = "experimental-features = nix-command flakes ca-derivations";
    settings = {
      auto-optimise-store = true;
      substituters = [
        "https://cache.nixos.org"
        "https://iohk.cachix.org"
        "https://cache.iog.io"
        "https://public-plutonomicon.cachix.org"
      ];
      trusted-public-keys = [
        "iohk.cachix.org-1:DpRUyj7h7V830dp/i6Nti+NEO2/nhblbov/8MW7Rqoo="
        "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
        "cache.iog.io:f/Ea+s+dFdN+3Y/G+FDgSq+a5NEWhJGzdjvKNGv0/EQ="
        "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
        "public-plutonomicon.cachix.org-1:3AKJMhCLn32gri1drGuaZmFrmnue+KkKrhhubQk/CWc="
      ];
      trusted-users = [
        "root"
        "pi"
      ];
      allowed-users = [
        "root"
        "pi"
      ];
    };
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

