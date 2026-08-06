{ ... }: {
  xdg.mime.enable = true;
  xdg.configFile."mimeapps.list".force = true;

  # NOTE: these *-flags.conf files are an Arch launcher-script convention;
  # neither upstream Chromium/Brave nor the nixpkgs wrappers read them, so
  # they are inert here. Kept only as documentation of intent. Hardware
  # video decode is enabled by the nixpkgs brave wrapper
  # (--enable-features=AcceleratedVideoDecodeLinuxGL) and Wayland comes from
  # NIXOS_OZONE_WL --ozone-platform-hint=auto.
  xdg.configFile."brave-flags.conf".text = ''
    --ozone-platform=wayland
  '';
  xdg.configFile."chromium-flags.conf".text = ''
    --ozone-platform=wayland
  '';

  xdg.mimeApps = {
    enable = true;
    associations.added = {
      "application/x-zerosize" = "code.desktop";
      "image/svg+xml" = "brave-browser.desktop";
      "video/x-matroska" = [ "org.xfce.Parole.desktop" "vlc.desktop" ];
    };
    defaultApplications = {
      "text/html" = "brave-browser.desktop";
      "x-scheme-handler/about" = "brave-browser.desktop";
      "x-scheme-handler/http" = "brave-browser.desktop";
      "x-scheme-handler/https" = "brave-browser.desktop";
      "x-scheme-handler/unknown" = "brave-browser.desktop";
    };
  };
}
