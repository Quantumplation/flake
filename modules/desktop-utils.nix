{ pkgs, ... }: {
  environment.systemPackages = with pkgs; [
    # Web & Communication
    brave
    signal-desktop

    # File management
    baobab    # Disk space usage
    nautilus  # GNOME file manager

    # Media
    vlc
    obs-studio
    mypaint
    digikam
    noson    # Sonos controller (GUI + noson-cli)

    # Wayland utilities
    cliphist
    wl-clipboard
    wdisplays
    wofi-power-menu
    wayvnc
    wlr-randr

    # Hyprland utilities
    hyprpicker
    hyprsunset
    brightnessctl
    pamixer
    playerctl
    gnome-themes-extra
    pavucontrol

    # System utilities
    blueman    # Bluetooth management (replaces blueberry which was removed upstream)
    openrgb    # RGB lighting control

    # Cloud & DevOps
    awscli2
    aws-vault

    # AI/Development tools
    claude-code

    # Misc tools
    zip
    unzip
    curl
    jq
    tree
    sops
    age
    ssh-to-age
    gnupg
  ];

  # Services
  services.tailscale.enable = true;
  services.gvfs.enable = true;
}
