{ pkgs, ... }: {
  gtk = let
    gtkTheme = {
      package = pkgs.gnome-themes-extra;
      name = "Adwaita:dark";
    };
  in {
    enable = true;
    theme = gtkTheme;
    gtk4.theme = gtkTheme;

    # No "Recent" list in GTK file choosers — including the portal picker,
    # which is what every app now gets (xdg-desktop-portal-gtk is a GTK3
    # binary, so the gtk3 key is the one that actually matters here; gtk4 is
    # set for other apps).
    #
    # NOT done via `gsettings set org.gnome.desktop.privacy
    # remember-recent-files false`, which is the usual advice: that schema
    # isn't installed on this machine (no GNOME), so nothing would read it.
    gtk3.extraConfig."gtk-recent-files-enabled" = false;
    gtk4.extraConfig."gtk-recent-files-enabled" = false;
  };
}
