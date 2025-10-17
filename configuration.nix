{ config, pkgs, lib, inputs, ... }:

{
  imports = [
    ./hardware-configuration.nix
    ./packages/sops.nix
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
  security.rtkit.enable = true;
  services = {
    pulseaudio.enable = false;
    pipewire = {
      enable = true;
      alsa.enable = true;
      pulse.enable = true;
      jack.enable = true;
      wireplumber = {
        enable = true;
        configPackages = [
          (pkgs.writeTextDir "share/wireplumber/wireplumber.conf.d/51-disable-hdmi.conf" ''
            monitor.alsa.rules = [
              {
                matches = [
                  {
                    node.name = "~alsa_output.pci-.*hdmi.*"
                  }
                ]
                actions = {
                  update-props = {
                    node.disabled = true
                  }
                }
              }
            ]
          '')
        ];
      };
    };
    # Lighting automation
    hardware.openrgb.enable = true;

    greetd = {
      enable = true;
      settings.default_session.command = "${pkgs.tuigreet}/bin/tuigreet --time --cmd Hyprland";
    };
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

  programs.hyprland = {
    enable = true;
    xwayland.enable = true;
    package = inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.hyprland;
    portalPackage = pkgs.xdg-desktop-portal-hyprland;
  };

  # Programs that aren't managed by homemanager
  programs._1password.enable = true;
  programs._1password-gui = {
    enable = true;
    polkitPolicyOwners = [ "pi" ];
  };
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
    noto-fonts
    noto-fonts-emoji
    nerd-fonts.caskaydia-mono
  ];

  environment = {
    variables = {
      TERMINAL = "alacritty";
      EDITOR = "vim";
      VISUAL = "vim";
    };
    systemPackages = with pkgs; [
      # Compilers
      gcc
      clang
      llvmPackages.libclang
      llvmPackages.libcxxClang

      # Linker & friends
      lld
      binutils
      cmake
      gnumake
      gnum4

      # System libraries
      glib
      openssl
      openssl.dev
      zlib
      zlib.dev

      # Core tools
      tailscale
      brave
      zip
      unzip
      curl

      # Developer tools
      meld             # Diff / merge
      wget             # CLI file download
      alejandra        # Nix file formatting
      python3
      cachix           # Nix caching
      nodejs_20
      inotify-tools    # filewatching
      arduino
      typst
      bun
      kubectl
      k9s
      aiken

      # Rust toolchain
      (rust-bin.selectLatestNightlyWith (t:
        t.default.override {
          extensions = [ "rustfmt" "clippy" "rust-src" ];
        }
      ))

      # Golang toolchain
      gotools
      go-tools
      gopls
      delve            # debugger
      gobject-introspection
      buf

      # Communication
      discord
      signal-desktop

      # Utilities
      baobab    # Disk space usage
      nautilus  # GNOME file manager
      cliphist
      wl-clipboard
      awscli2
      aws-vault
      vlc
      jq
      sops
      age
      ssh-to-age
      gnupg
      wdisplays
      wofi-power-menu

      # Hyprland stuff
      hyprshot
      hyprpicker
      hyprsunset
      brightnessctl
      pamixer
      playerctl
      gnome-themes-extra
      pavucontrol
      kdePackages.xwaylandvideobridge

      # Staple replacements
      fzf
      zoxide
      ripgrep
      eza
      fd

      # Misc tools
      obs-studio
      mypaint
      digikam
      openrgb # Lighting control
      wayvnc
      wlr-randr

      # System stuff?
      blueberry # Wayland bluetooth stuff
      pkg-config
      webkitgtk_6_0
      libsoup_3

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
      access-tokens = [];
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
