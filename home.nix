inputs: {
  config,
  lib,
  pkgs,
  inputs,
  ...
}: let
  themes = import ./themes.nix;
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
        ./ssh.nix
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
        # autorandr.enable = true;
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

        # autorandr = {
        #   enable = true;
        #   profiles = {
        #     "default" = {
        #       fingerprint = {
        #         "DP-2" = "00ffffffffffff001e6d7f5bc0340600051e0104b53c22789f8cb5af4f43ab260e5054254b007140818081c0a9c0b300d1c08100d1cf28de0050a0a038500830080455502100001a000000fd003090e6e63c010a202020202020000000fc003237474c3835300a2020202020000000ff003030354e54504342593732300a010602031a7123090607e305c000e606050160592846100403011f13565e00a0a0a029503020350055502100001a909b0050a0a046500820880c555021000000b8bc0050a0a055500838f80c55502100001a00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001a";
        #         "DP-4" = "00ffffffffffff001e6d7f5b1d380600051e0104b53c22789f8cb5af4f43ab260e5054254b007140818081c0a9c0b300d1c08100d1cf28de0050a0a038500830080455502100001a000000fd003090e6e63c010a202020202020000000fc003237474c3835300a2020202020000000ff003030354e544b46425a3538310a01a102031a7123090607e305c000e606050160592846100403011f13565e00a0a0a029503020350055502100001a909b0050a0a046500820880c555021000000b8bc0050a0a055500838f80c55502100001a00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001a";
        #       };
        #       config = {
        #         "DP-2" = {
        #           enable = true;
        #           crtc = 1;
        #           mode = "2560x1440";
        #           position = "0x0";
        #           rate = "144";
        #           extraConfig = ''
        #             x-prop-non_desktop 0
        #           '';
        #         };
        #         "DP-4" = {
        #           enable = true;
        #           crtc = 0;
        #           mode = "2560x1440";
        #           position = "2560x0";
        #           rate = "144.00";
        #           extraConfig = ''
        #             x-prop-non_desktop 0
        #           '';
        #         };
        #       };
        #     };
        #   };
        # };

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

        # rofi = {
        #   enable = true;
        #   cycle = false;
        #   terminal = "\${pkgs.alacritty}/bin/alacritty";
        #   theme = "purple";
        #   plugins = [ pkgs.rofi-calc pkgs.rofi-emoji pkgs.rofi-power-menu pkgs.rofi-pulse-select ];
        #   extraConfig = {
        #     show-icons = true;
        #     icon-theme = "Papirus";
        #     hide-scrollbar = true;
        #     disable-history = false;
        #     auto-select = true;
        #     modes = [ "window" "drun" "calc" "emoji" ];
        #     hover-select = true;
        #     me-select-entry = "";
        #     me-accept-entry = [ "MousePrimary" ];
        #   };
        # };

        vim = {
          enable = true;
        };


        # vscode = {
        #   enable = true;
        #   # package = (pkgs.vscode.override{ isInsiders = true; }).overrideAttrs (oldAttrs: rec {
        #   #   src = (builtins.fetchTarball {
        #   #     url = "https://update.code.visualstudio.com/latest/linux-x64/insider";
        #   #     sha256 = "16vcginn0w22aciawibch0y7dibqfjbkik1nhs23x76abww1qkzv";
        #   #   });
        #   #   version = "latest";
        #   # });
        # };
      };
    };
  };
}
