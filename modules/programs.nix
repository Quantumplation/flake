{ pkgs, ... }:
let
  # Chromium prompts to hand slack:// off to xdg-open even though nothing on this
  # system claims the scheme (`gio mime x-scheme-handler/slack` -> no default), so
  # the launch silently no-ops and Slack's web page sits there waiting out its own
  # timer before it offers the in-browser option. Blocking the scheme drops the
  # navigation without a dialog. Pairs with ~/proj/always-slack, a sideloaded
  # extension that skips the stall behind it. Verify at brave://policy.
  #
  # Tradeoff: if the Slack desktop app is ever installed, slack:// deep links will
  # stop reaching it until this is removed.
  #
  # Must be "slack://*", not "slack://". Filters parse as
  # [scheme://][.]host[:port][/path][@query], and for custom schemes Chromium only
  # accepts the whole-scheme wildcards `scheme:*` and `scheme://*`; a bare
  # "slack://" has no host and shows up as "Policy parsing error" in brave://policy.
  blockSlackScheme = builtins.toJSON { URLBlocklist = [ "slack://*" ]; };
in {
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

  # Brave and Chromium each read managed policy from their own /etc path.
  environment.etc."brave/policies/managed/no-slack-scheme.json".text = blockSlackScheme;
  environment.etc."chromium/policies/managed/no-slack-scheme.json".text = blockSlackScheme;

  programs.fish.enable = true;
  hardware.acpilight.enable = true;
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
    vulkan-loader
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
