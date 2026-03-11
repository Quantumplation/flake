{ pkgs, lib, ... }: {
  home.activation.patchCompactc = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    if [ -L "$HOME/.compact/bin/compactc" ]; then
      target=$(${pkgs.coreutils}/bin/readlink -f "$HOME/.compact/bin/compactc")
      if [ -f "$target" ]; then
        $DRY_RUN_CMD ${pkgs.gnused}/bin/sed -i '1s|^#!.*|#!/usr/bin/env bash|' "$target"
      fi
    elif [ -f "$HOME/.compact/bin/compactc" ]; then
      $DRY_RUN_CMD ${pkgs.gnused}/bin/sed -i '1s|^#!.*|#!/usr/bin/env bash|' "$HOME/.compact/bin/compactc"
    fi
  '';

  home.packages = [
    (pkgs.stdenv.mkDerivation rec {
      pname = "compact";
      version = "0.3.0";

      src = pkgs.fetchurl {
        url = "https://github.com/midnightntwrk/compact/releases/download/compact-v${version}/compact-x86_64-unknown-linux-musl.tar.xz";
        hash = "sha256-s9x/pMfFLLXi7V8ppGHdkQ70zSu4mB0gPctrB9ZOT5w=";
      };

      sourceRoot = ".";

      nativeBuildInputs = [ pkgs.xz ];

      installPhase = ''
        mkdir -p $out/bin
        cp compact-x86_64-unknown-linux-musl/compact $out/bin/
        chmod +x $out/bin/compact
      '';

      meta = with pkgs.lib; {
        description = "CLI tool for working with the Compact language and language server";
        homepage = "https://github.com/midnightntwrk/compact";
        platforms = [ "x86_64-linux" ];
      };
    })
  ];
}
