{ pkgs, ... }: {
  programs.fish = {
    enable = true;
    interactiveShellInit = ''
      set fish_greeting # Disable greeting
      ${pkgs.any-nix-shell}/bin/any-nix-shell fish --info-right | source
    '';
    shellInit = ''
      set -Ux NIX_LD /run/current-system/sw/share/nix-ld/lib/ld.so
      set -Ux NIX_LD_LIBRARY_PATH /run/current-system/sw/share/nix-ld/lib
      set -Ux LD_LIBRARY_PATH "${pkgs.stdenv.cc.cc.lib}/lib:${pkgs.openssl.out}/lib"
      set -Ux PKG_CONFIG_PATH "${pkgs.openssl.dev}/lib/pkgconfig:${pkgs.libsoup_3.dev}:${pkgs.glib.dev}:${pkgs.gobject-introspection.dev}"
      set -Ux GOPRIVATE github.com/SundaeSwap-finance
      set --global tide_right_prompt_items status cmd_duration node rustc go aws time
    '';
    functions = {
      nrs = {
        description = "NixOS rebuild switch with auto git-add";
        body = ''
          echo "Adding new files to git..."
          git add -v .
          echo ""
          echo "Running nixos-rebuild..."
          sudo nixos-rebuild switch --flake .#goldwasser
        '';
      };
    };
    plugins = with pkgs.fishPlugins; [
      {
        # TODO: declarative tide config; remember to run tide configure when you first set this up
        name = "tide";
        src = pkgs.fetchFromGitHub {
          owner = "IlanCosman";
          repo = "tide";
          rev = "a34b0c2809f665e854d6813dd4b052c1b32a32b4";
          sha256 = "sha256-ZyEk/WoxdX5Fr2kXRERQS1U1QHH3oVSyBQvlwYnEYyc=";
        };
      }
    ];
  };
}
