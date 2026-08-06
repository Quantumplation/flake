{
  config,
  lib,
  pkgs,
  inputs,
  ...
}: let
  themes = import ./modules/themes.nix;
  selectedTheme = themes.${themes.selected};
  selectedColorScheme =
    if selectedTheme ? custom-palette
    then { slug = themes.selected; name = themes.selected; palette = selectedTheme.custom-palette; }
    else inputs.nix-colors.colorSchemes.${selectedTheme.base16-theme};
in {

  home-manager = {
    backupFileExtension = "backup";
    useGlobalPkgs = true;
    useUserPackages = true;
    # Every home module is a plain module taking { inputs, ... } via
    # extraSpecialArgs — no more curried (import ./foo.nix inputs) pattern.
    extraSpecialArgs = { inherit inputs; };
    users.pi = {
      imports = [
        inputs.nix-colors.homeManagerModules.default
        ./packages/hyprland
        ./packages/hyprlock.nix
        ./packages/hyprshell.nix
        ./packages/hyprpaper.nix
        ./packages/hypridle.nix
        ./packages/ghostty.nix
        ./packages/git.nix
        ./packages/fish.nix
        ./packages/btop.nix
        ./packages/vim.nix
        ./packages/zed.nix
        ./packages/obsidian.nix
        ./packages/tldraw.nix
        ./packages/waybar.nix
        ./packages/wofi.nix
        ./packages/wayvnc.nix
        ./packages/scripts.nix
        ./packages/theme-data.nix
        ./packages/compact.nix
        ./packages/browser.nix
        ./packages/gtk.nix
        ./packages/swaync.nix
        ./packages/atuin.nix
        ./packages/aws.nix
        ./modules/ssh.nix
      ];

      colorScheme = selectedColorScheme;

      home = {
        username = "pi";
        homeDirectory = "/home/pi";
        stateVersion = "22.11";

        sessionPath = [
          "$HOME/.local/bin"
        ];

        sessionVariables = with pkgs; {
          "AWS_REGION" = "us-east-2";
          # CACHIX_AUTH_TOKEN is now managed via sops - add to shell config if needed
          LIBCLANG_PATH = "${llvmPackages.libclang.lib}/lib";
        };

        pointerCursor = {
          name = "Bibata-Modern-Classic";
          package = pkgs.bibata-cursors;
          size = 22;
          gtk.enable = true;
          x11.enable = true;
        };

      };

      # Workaround for something? https://github.com/nix-community/home-manager/issues/2064#issuecomment-887300055
      systemd.user.targets.tray = {
        Unit = {
          Description = "Home Manager System Tray";
          Requires = [ "graphical-session-pre.target" ];
        };
      };

      programs = {
        home-manager.enable = true;

        go = {
          enable = true;
          env.GOPRIVATE = [
            "github.com/SundaeSwap-finance"
          ];
        };
      };
    };
  };
}
