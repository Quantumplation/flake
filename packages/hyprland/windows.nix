{
  config,
  pkgs,
  ...
}: {
  wayland.windowManager.hyprland.settings = {
    windowrule = [
      # Todo panel (hotkey-toggled floating quick-add). Opens stashed in the
      # special workspace (winit can't map hidden on Wayland); the panel's
      # show/hide moves it in and out, quake-terminal style. NO `pin on`:
      # Hyprland silently refuses to move pinned windows between workspaces,
      # which breaks hiding entirely.
      "match:class todo-panel, float on, size 760 600, center on"
      "match:class todo-panel, workspace special:todo silent"
      # opaque: the panel is transparent-with-own-frame; theme opacity washes it out
      "match:class todo-panel, opacity 1.0"
      # no compositor border or blur: the panel paints its own card, and the
      # transparent strip below it must stay perfectly clear so the hint text
      # floats over the bare desktop (blur would haze the whole surface)
      "match:class todo-panel, border_size 0"
      "match:class todo-panel, no_blur on"

      # Wattson panel (power history, toggled from the waybar battery icon).
      # Same stash-in-special-workspace mechanics as todo-panel above.
      "match:class wattson-panel, float on, size 880 640, center on"
      "match:class wattson-panel, workspace special:wattson silent"
      "match:class wattson-panel, opacity 1.0"
      "match:class wattson-panel, border_size 0"
      "match:class wattson-panel, no_blur on"

      # Claude dashboard (waybar dropdown): full-height overlay panel hugging
      # the right screen edge, sliding in like a notification center. The
      # dashboard process computes its exact geometry from the focused
      # monitor at startup (windowrule move formulas proved unreliable, and
      # tiling it mangles existing layouts; `addreserved` at runtime resets
      # monitor scale, so overlay it is).
      "match:title ClaudeDashboard, float on, pin on, size 560 90%"
      "match:title ClaudeDashboard, animation slide right"

      # Moraine, my terrain generator project
      "match:class moraine, float on, size 1280 800, center on"

      # Apoapsis, Bevy game project
      "match:class apoapsis, float on, size 1280 800, center on"

      # leaf2 and any other macroquad project (miniquad hardcodes this X11
      # class; no size rule — the game's own Conf controls resolution)
      "match:class miniquad-application, float on, center on"

      # Eternl Cardano wallet (Brave PWA)
      "float true, match:class ^(brave-kmhcihpebfmpgmihbkipmjlmmioameka-Default)$"

      # Brave download/save dialogs.
      #
      # Class is ^(brave|brave-browser)$: the running window reports
      # `brave-browser`, so the old bare ^(brave)$ was anchored against a name
      # nothing uses and never matched. Both spellings are kept because the
      # class has varied across Brave/nixpkgs versions.
      "float true, match:class ^(brave|brave-browser)$, match:title ^(wants to save).*"
      "pin true, match:class ^(brave|brave-browser)$, match:title ^(wants to save).*"
      "size 941 250, match:class ^(brave|brave-browser)$, match:title ^(wants to save).*"
      "center true, match:class ^(brave|brave-browser)$, match:title ^(wants to save).*"
      # NOTE: that title regex expects the title to *start* with "wants to
      # save"; Brave usually prefixes the site name. Left as-is (unverified,
      # separate from the picker fix) — see the File pickers block below, which
      # now covers Brave's Open File / Save File / Select Files dialogs
      # class-independently, so the old per-Brave picker rules were dropped.

      # Default these to floating
      "float true, match:class ^(org.pulseaudio.pavucontrol|\\.?blueman-manager(-wrapped)?)$"
      "float true, match:class ^(steam)$"
      "fullscreen true, match:class ^(com.libretro.RetroArch)$"

      # Opacity rules
      "opacity 1.0 1.0, match:class ^(brave|chromium|google-chrome)$, match:title .*[Yy]ou[Tt]ube.*"
      "opacity 1.0 0.97, match:class ^(brave|chromium|google-chrome)$"
      "opacity 1.0 1.0, match:class ^(zoom|vlc|kdenlive|com.obsproject.Studio)$"

      # Fix XWayland dragging
      "no_focus true, match:class ^$, match:title ^$, match:xwayland true, match:float true, match:fullscreen false, match:pin false"


      # Clipse clipboard manager
      "float true, match:class ^(clipse)$"
      "size 622 652, match:class ^(clipse)$"
      "stay_focused true, match:class ^(clipse)$"

      # System utilities
      "size 800 600, match:class ^(org.pulseaudio.pavucontrol)$"
      "center true, match:class ^(org.pulseaudio.pavucontrol)$"

      "size 700 500, match:class ^(\\.?blueman-manager(-wrapped)?)$"
      "center true, match:class ^(\\.?blueman-manager(-wrapped)?)$"

      # Network manager
      "float true, match:class ^(nm-connection-editor)$"
      "size 600 500, match:class ^(nm-connection-editor)$"
      "center true, match:class ^(nm-connection-editor)$"

      # Calculator
      "float true, match:class ^(org.gnome.Calculator|qalculate-gtk)$"
      "size 400 500, match:class ^(org.gnome.Calculator|qalculate-gtk)$"
      "center true, match:class ^(org.gnome.Calculator|qalculate-gtk)$"

      # File pickers.
      #
      # Matched on title ALONE, deliberately — class is useless here. A picker
      # only carries the `xdg-desktop-portal-gtk` class when the portal handles
      # it; when an app falls back to its own in-process GTK dialog it inherits
      # the *app's* class, which need not even match the app's own main window
      # (tldraw's picker is `tldraw-offline`, its main window `tldraw offline`).
      # The old class-scoped rule therefore never fired for those, and the
      # picker got tiled into whatever slot was free — the "distorted and
      # unusable" case.
      #
      # `match:modal` exists in 0.55 but does NOT work for this: it keys off
      # xdg-dialog-v1, which GTK only advertises from GTK4. Electron/Chromium
      # pickers are GTK3, and verified as not matching. Don't "simplify" to it.
      #
      # Titles are exact-anchored, not substring: `.*Save.*` would float any
      # browser tab that happens to say "Save" in its title.
      "float true, match:title ^(Open|Open File|Open Files|Open Folder|Save|Save As|Save File|Save File As|Save Image|Select File|Select Files|Select Folder|Select a File|Select Folder to Upload|Choose File|Choose Files|File Upload|Upload File)$"
      "size 900 600, match:title ^(Open|Open File|Open Files|Open Folder|Save|Save As|Save File|Save File As|Save Image|Select File|Select Files|Select Folder|Select a File|Select Folder to Upload|Choose File|Choose Files|File Upload|Upload File)$"
      "center true, match:title ^(Open|Open File|Open Files|Open Folder|Save|Save As|Save File|Save File As|Save Image|Select File|Select Files|Select Folder|Select a File|Select Folder to Upload|Choose File|Choose Files|File Upload|Upload File)$"

      # Picture-in-Picture
      "float true, match:title ^(Picture-in-Picture)$"
      "size 25% 25%, match:title ^(Picture-in-Picture)$"
      "pin true, match:title ^(Picture-in-Picture)$"
      "move 72% 72%, match:title ^(Picture-in-Picture)$"

      # Max size constraint
      "max_size 1400 900, match:float true"
      # ...except the Claude sidebar, which is intentionally near-full-height
      "match:title ClaudeDashboard, max_size 560 2400"

      # Prevent screen from sleeping
      "idle_inhibit fullscreen, match:class ^(brave|chromium|firefox)$"
      "idle_inhibit focus, match:class ^(mpv|vlc|celluloid)$"
      "idle_inhibit focus, match:class ^(com.obsproject.Studio)$"

      # Hide xwaylandvideobridge
      "opacity 0.0 override, match:class ^(xwaylandvideobridge)$"
      "no_anim true, match:class ^(xwaylandvideobridge)$"
      "no_initial_focus true, match:class ^(xwaylandvideobridge)$"
      "max_size 1 1, match:class ^(xwaylandvideobridge)$"
      "no_blur true, match:class ^(xwaylandvideobridge)$"

      # Misc
      "tile true, match:class ^(chromium)$"
      "suppress_event maximize, match:class .*"
    ];

    layerrule = [
      "blur true, match:namespace wofi"
      "blur true, match:namespace waybar"
      "ignore_alpha 0.3, match:namespace waybar"
      "blur true, match:namespace swaync-control-center"
      "blur true, match:namespace swaync-notification-window"
      "ignore_alpha 0.3, match:namespace swaync-control-center"
      "ignore_alpha 0.3, match:namespace swaync-notification-window"
    ];
  };
}
