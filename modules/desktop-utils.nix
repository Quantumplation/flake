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

    # Wayland utilities
    cliphist
    wl-clipboard
    wdisplays
    wofi-power-menu
    wayvnc
    wlr-randr

    # Hyprland utilities
    hyprshot
    hyprpicker
    hyprsunset
    brightnessctl
    pamixer
    playerctl
    gnome-themes-extra
    pavucontrol
    kdePackages.xwaylandvideobridge

    # System utilities
    blueberry  # Bluetooth management
    openrgb    # RGB lighting control

    # Cloud & DevOps
    awscli2
    aws-vault

    # Misc tools
    zip
    unzip
    curl
    jq
    sops
    age
    ssh-to-age
    gnupg
  ];

  # Services
  services.tailscale.enable = true;
}
