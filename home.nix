inputs: {
  config,
  lib,
  pkgs,
  inputs,
  ...
}: let
  themes = import ./modules/themes.nix;
  selectedTheme = themes.${"tokyo-night"};
  generatedColorScheme = null;
in {

  home-manager = {
    backupFileExtension = "backup";
    useGlobalPkgs = true;
    useUserPackages = true;
    users.pi = {
      imports = [
        inputs.nix-colors.homeManagerModules.default
        (import ./packages/hyprland inputs)
        (import ./packages/hyprlock.nix inputs)
        (import ./packages/hyprshell.nix inputs)
        (import ./packages/hyprpaper.nix)
        (import ./packages/hypridle.nix)
        (import ./packages/ghostty.nix)
        (import ./packages/git.nix)
        (import ./packages/fish.nix)
        (import ./packages/btop.nix)
        (import ./packages/vim.nix)
        (import ./packages/zed.nix)
        (import ./packages/obsidian.nix)
        (import ./packages/waybar.nix inputs)
        (import ./packages/wofi.nix)
        (import ./packages/wayvnc.nix inputs)
        (import ./packages/scripts.nix)
        ./packages/snap-back
        ./modules/ssh.nix
      ];

      colorScheme = inputs.nix-colors.colorSchemes.${selectedTheme.base16-theme};

      home = {
        username = "pi";
        homeDirectory = "/home/pi";
        stateVersion = "22.11";

        packages = with pkgs; [
          swaynotificationcenter
        ];

        sessionPath = [
        ];

        sessionVariables = with pkgs; {
          "AWS_REGION" = "us-east-2";
          # CACHIX_AUTH_TOKEN is now managed via sops - add to shell config if needed
          LIBCLANG_PATH = "${llvmPackages.libclang.lib}/lib";
          LD_LIBRARY_PATH = "$LD_LIBRARY_PATH:${lib.makeLibraryPath ([stdenv xorg.libX11 xorg.libX11.dev xorg.libXcursor xorg.libXi libxkbcommon libGL vulkan-headers vulkan-loader fontconfig])}";
        };

        pointerCursor = {
          name = "Adwaita";
          package = pkgs.adwaita-icon-theme;
          size = 24;
          gtk.enable = true;
          x11.enable = true;
        };

      };

      xdg.mime.enable = true;
      xdg.configFile."mimeapps.list".force = true;
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

      services = {
        swaync = {
          enable = true;
          style = ./assets/swaync/style.css;
          settings = {
            positionX = "right";
            positionY = "top";
            control-center-width = 400;
            control-center-height = 600;
            control-center-margin-top = 10;
            control-center-margin-bottom = 10;
            control-center-margin-right = 10;
            control-center-margin-left = 10;
            notification-window-width = 400;
            timeout = 5;
            timeout-low = 3;
            timeout-critical = 0;
            fit-to-screen = false;
            keyboard-shortcuts = true;
            image-visibility = "when-available";
            notification-icon-size = 48;
            notification-body-image-height = 100;
            notification-body-image-width = 200;
            transition-time = 200;
            hide-on-clear = true;
            hide-on-action = true;
            script-fail-notify = false;
          };
        };
      };

      # Workaround for something? https://github.com/nix-community/home-manager/issues/2064#issuecomment-887300055
      systemd.user.targets.tray = {
        Unit = {
          Description = "Home Manager System Tray";
          Requires = [ "graphical-session-pre.target" ];
        };
      };

      nixGL.vulkan.enable = true;

      gtk = {
        enable = true;
        theme = {
          package = pkgs.gnome-themes-extra;
          name = "Adwaita:dark";
        };
      };

      programs = {
        home-manager.enable = true;

        atuin = {
          enable = true;
          settings = {
            show_preview = true;
            invert = false;
            inline_height = 10;
            style = "auto";
            enter_accept = true;
          };
          settings = {
            sync_address = "https://api.atuin.sh";
            key_path = config.sops.secrets."atuin/key".path;
            session_path = config.sops.secrets."atuin/session".path;
          };
        };

        awscli = {
          enable = true;
          settings = {
            "default" = {
              "region" = "us-east-2";
            };
            "profile dev-admin" = {
              "sso_session" = "pi";
              "sso_account_id" = "529991308818";
              "sso_role_name" = "AWSAdministratorAccess";
              "region" = "us-east-2";
            };
            "profile prod-admin" = {
              "sso_session" = "pi";
              "sso_account_id" = "705895683800";
              "sso_role_name" = "AWSAdministratorAccess";
              "region" = "us-east-2";
            };
            "sso-session pi" = {
              "sso_start_url" = "https://d-9a672d8c7d.awsapps.com/start/#";
              "sso_region" = "us-east-2";
              "sso_registration_scopes" = "sso:account:access";
            };
          };
        };

        go = {
          enable = true;
          env.GOPRIVATE = [
            "github.com/SundaeSwap-finance"
          ];
        };

        vim = {
          enable = true;
        };
      };
    };
  };
}
