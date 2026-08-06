{ pkgs, ... }: let
  pname = "tldraw-offline";
  version = "1.12.1";

  # tldraw offline is not in nixpkgs; upstream ships an Electron AppImage (and a
  # .deb) per release. wrapType2 mounts the AppImage and runs it under an FHS
  # env, so there is nothing to patchelf — the only maintenance is bumping
  # version + hash when a release lands.
  #
  # Re-hash with:
  #   nix store prefetch-file https://github.com/tldraw/tldraw-offline/releases/download/v<ver>/tldraw-offline-linux-x86_64.AppImage
  src = pkgs.fetchurl {
    url = "https://github.com/tldraw/tldraw-offline/releases/download/v${version}/tldraw-offline-linux-x86_64.AppImage";
    hash = "sha256-/DCjyk/124E48RWHSvfsYwHHbPuyhUuOxeL2z9rgtGI=";
  };

  # Only needed to lift the .desktop entry and icons out of the image.
  contents = pkgs.appimageTools.extract { inherit pname version src; };

  tldraw-offline = pkgs.appimageTools.wrapType2 {
    inherit pname version src;

    extraInstallCommands = ''
      install -Dm444 ${contents}/${pname}.desktop \
        $out/share/applications/${pname}.desktop

      # AppRun only exists inside the mounted image; point Exec at the wrapper.
      # --no-sandbox stays: chrome-sandbox in the store is not setuid, and
      # NixOS's unprivileged userns is what Electron falls back on anyway.
      substituteInPlace $out/share/applications/${pname}.desktop \
        --replace-fail 'Exec=AppRun' 'Exec=${pname}'

      cp -r ${contents}/usr/share/icons $out/share/icons
    '';

    meta = with pkgs.lib; {
      description = "Local-first desktop whiteboard — tldraw with .tldraw files, no accounts or servers";
      homepage = "https://offline.tldraw.com/";
      license = licenses.unfree; # proprietary desktop app around the tldraw SDK
      platforms = [ "x86_64-linux" ];
      mainProgram = pname;
    };
  };
in {
  home.packages = [ tldraw-offline ];
}
