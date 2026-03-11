{ pkgs, ... }: {
  # System-wide programs (Hyprland is in packages/hyprland/system.nix)

  programs._1password.enable = true;
  programs._1password-gui = {
    enable = true;
    polkitPolicyOwners = [ "pi" ];
  };

  # 1Password needs a secret service to persist device auth tokens
  # (without this, it requires 2FA on every launch)
  services.gnome.gnome-keyring.enable = true;
  services.gnome.gcr-ssh-agent.enable = false;
  security.pam.services.greetd.enableGnomeKeyring = true;

  # Allow 1Password browser extension to connect from wrapped Brave binary
  environment.etc."1password/custom_allowed_browsers" = {
    text = ''
      brave
      .brave-wrapped
    '';
    mode = "0755";
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

  # Nix-ld for running unpatched binaries
  programs.nix-ld.enable = true;
  programs.nix-ld.libraries = with pkgs; [
    stdenv.cc.cc.lib
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
    libxcb
    libxkbcommon
    mesa
    nspr
    nss
    pango
    systemd
    icu
    openssl
    libx11
    libxscrnsaver
    libxcomposite
    libxcursor
    libxdamage
    libxext
    libxfixes
    libxi
    libxrandr
    libxrender
    libxtst
    libxkbfile
    libxshmfence
    zlib
  ];
}
