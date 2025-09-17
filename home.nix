{ config, lib, pkgs, ... }:

{
  imports = [
    ./polybar/default.nix
    ./ssh.nix
  ];

  home-manager = {
    backupFileExtension = "backup";
    useGlobalPkgs = true;
    useUserPackages = true;
    users.pi = {
      home = {
        username = "pi";
        homeDirectory = "/home/pi";
        stateVersion = "22.11";
    
        packages = with pkgs; [
        ];

        sessionPath = [
          "${pkgs.rofi-pulse-select}/bin"
        ];

        sessionVariables = with pkgs; {
          "AWS_REGION" = "us-east-2";
          "CACHIX_AUTH_TOKEN" = import ./cachix.nix;
          LIBCLANG_PATH = "${llvmPackages_17.libclang.lib}/lib";
          LD_LIBRARY_PATH = "$LD_LIBRARY_PATH:${lib.makeLibraryPath ([stdenv xorg.libX11 xorg.libX11.dev xorg.libXcursor xorg.libXi libxkbcommon libGL vulkan-headers vulkan-loader fontconfig])}";
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

      xsession.windowManager.bspwm = {
        enable = true;
        settings = {
          border_width = 2;
          window_gap = 14;

          split_ratio = 0.52;
          borderless_monocle = true;
          gapless_monocle = true;

          focused_border_color = "#a6bc69";
        };
        alwaysResetDesktops = true;
        monitors = {
          "%DP-2" = [ "A" "B" ];
          "DP-4" = [ "C" "D" ];
        };
        startupPrograms = [
          "systemctl --user restart polybar"
          "xsetroot -cursor_name left_ptr"
          "betterlockscreen -w blur 0.5"
          "feh --bg-scale --random ~/Pictures/Wallpapers"
        ];
      };

      services = {
        autorandr.enable = true;
        betterlockscreen = {
          enable = true;
          arguments = [ "-u ~/Pictures/Wallpapers" ];
        };
        dunst = {
          enable = true;
          settings = {
            global = {
              monitor = 0;
              width = 280;
              height = 80;
              origin = "top-right";
              offset = "10x45";
              scale = 0;
              indicate_hidden = "yes";
              shrink = "no";
              separator_color = "auto";
              separator_height = 4;
              line_height = 4;
              padding = 15;
              horizontal_padding = 15;
              frame_width = 2;
              sort = "no";
              idle_threshold = 120;
              font = "JetBrainsMono Nerd Font 12";
              markup = "full";
              format = "%s\\n%b";
              alignment = "left";
              show_age_threshold = 60;
              word_wrap = "yes";
              ignore_newline = "no";
              stack_duplicates = false;
              hide_duplicate_count = "yes";
              show_indicators = "no";
              icon_position = "left";
              max_icon_size = 48;
              sticky_history = "yes";
              history_length = 20;
              browser = "${pkgs.brave}/bin/brave";
              always_run_script = "true";
              title = "Dunst";
              class = "Dunst";
            };
            urgency_low = {
              timeout = 2;
              background = "#20262C";
              foreground = "f1fcf9";
              frame_color = "#b4a1db";
            };
            urgency_normal = {
              timeout = 5;
              background = "#20262c";
              foreground = "#f1fcf9";
              frame_color = "#b4a1db";
            };
            urgency_critical = {
              timeout = 0;
              background = "#20262c";
              foreground = "#f1fcf9";
              frame_color = "#db86ba";
            };
          };
        };
        flameshot = {
          enable = true;
          settings = {
            General = {
              contrastOpacity = 188;
            };
          };
        };
        picom = {
          enable = true;
          fade = true;
          fadeDelta = 10;
          fadeSteps = [0.05 0.05];
          settings = {
            mark-wmwin-focused = true;
            mark-ovredir-focused = true;
            use-wemh-active-win = true;
            detect-rounded-corners = true;
            detect-client-opacity = true;
            dbe = false;
            unredir-if-possible = true;
            detect-transient = true;
            detect-client-leader = true;
            wintypes = {
              tooltip = {
                fade = true;
                shadow = false;
                opacity = 0.85;
                focus = true;
              };
            };
          };
        };
        polybar = {
          enable = true;
          package = pkgs.polybarFull;
          script = "${config.users.users.pi.home}/.config/polybar/launch.sh";
        };
        sxhkd = {
          enable = true;
          keybindings = {
            "super + @space" = "rofi -show drun";
            # Applications
            "super + a" = "ghostty";
            "super + b" = "brave";
            # "super + e" = "rofi -show file-browser-extended -file-browser-depth 3";
            "super + shift + e" = "thunar";
            "super + n" = "zed";
            "super + p" = "mypaint";

            # rofi plugins
            "super + c" = "rofi -show calc -terse | xclip -i -selection clipboard -rmlastnl";
            "super + shift + 2" = "rofi -show emoji";
            "super + v" = "${pkgs.rofi-pulse-select}/bin/rofi-pulse-select sink";
            "super + shift + v" = "${pkgs.rofi-pulse-select}/bin/rofi-pulse-select source";
            
            # Close
	    "super + {_,shift + }w" = "bspc node -{c,k}";
            # "super + alt + shift + {q,r}" = "bspc {quit, wm -r}";
            "super + y" = "rofi -show power-menu -modi power-menu:${pkgs.rofi-power-menu}/bin/rofi-power-menu -font 'JetBrainsMono Nerd Font 16'";
            "super + l" = "${pkgs.betterlockscreen}/bin/betterlockscreen -l";

            # Monocle mode
            "super + m" = "bspc desktop -l next";

            # Floating / tiled / fullscreen
            "super + {t,shift + t,s,f}" = "bspc node -t {tiled,pseud_tiled,floating,fullscreen}";

            # Move node between windows
            "super + alt + bracket{left,right}" = ''
               bspc node -m {prev,next} --follow
            '';
            # Move node between desktops
            "super + shift + bracket{left,right}" = "bspc node -d {next,prev}.local --follow";

            # Rotate or cylce nodes
            "super + {_,shift +}grave" = "bspc node @parent -R {90, 270}";
            # "super + {_,shift +}Tab" = "bspc node @parent -C {backward,forward}";
            "super + Tab" = "rofi -show window";

            # Switch desktops
            "super + ctrl + {_,shift +}Tab" = "bspc desktop -f {next,prev}.local";

            # Resize things
            "alt + button{1-3}" = "bspc pointer -g {move,resize_side,resize_corner}";
            "alt + !button{1-3}" = "bspc pointer -t %i, %i";
            "alt + @button{1-3}" = "bspc pointer -u";

            # Screenshot
            # 2 extra spaces required for proper formatting
            "ctrl + shift + 4" = ''
               mkdir -p ~/Pictures/Captures/$(date +"%Y-%m"); \
                 flameshot gui -c -p ~/Pictures/Captures/$(date +"%Y-%m")/
            '';
          };
        };
      };

      systemd.user.targets.tray = {
        Unit = {
          Description = "Home Manager System Tray";
          Requires = [ "graphical-session-pre.target" ];
        };
      };
  
      programs = {
        home-manager.enable = true;

        alacritty = {
          enable = true;
          settings = {
            window = {
              decorations = "full";
              opacity = 0.95;
            };
            font = rec {
              normal.family = "FiraCode Nerd Font";
              bold = { style = "Bold"; };
            };
            colors = {
              primary.background = "#212121";
              primary.foreground = "#c0c5ce";
              primary.bright_foreground = "#f3f4f5";
    
              cursor.text = "#212121";
              cursor.cursor = "#c0c5ce";
    
              normal = {
                black   = "#212121";
                red     = "#e57373";
                green   = "#a6bc69";
                yellow  = "#fac863";
                blue    = "#6699cc";
                magenta = "#c594c5";
                cyan    = "#5fb3b3";
                white   = "#c0c5ce";
              };
              bright = {
                black   = "#5c5c5c";
                red     = "#e57373";
                green   = "#a6bc69";
                yellow  = "#6699cc";
                magenta = "#c594c5";
                cyan    = "#5fb3b3";
                white   = "#f3f4f5";
              };
            };
            bell = {
              animation = "EaseOut";
              duration = 100;
              color = "0xc0c5ce";
            };
          };
        };

        atuin = {
          enable = true;
          settings = {
            show_preview = true;
            invert = false;
            inline_height = 10;
            style = "auto";
            enter_accept = true;
          };
          #settings = {
          #  key_path = config.sops.secrets."atuin/key".path;
          #};
        };

	autorandr = {
          enable = true;
          profiles = {
            "default" = {
              fingerprint = {
                "DP-2" = "00ffffffffffff001e6d7f5bc0340600051e0104b53c22789f8cb5af4f43ab260e5054254b007140818081c0a9c0b300d1c08100d1cf28de0050a0a038500830080455502100001a000000fd003090e6e63c010a202020202020000000fc003237474c3835300a2020202020000000ff003030354e54504342593732300a010602031a7123090607e305c000e606050160592846100403011f13565e00a0a0a029503020350055502100001a909b0050a0a046500820880c555021000000b8bc0050a0a055500838f80c55502100001a00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001a";
                "DP-4" = "00ffffffffffff001e6d7f5b1d380600051e0104b53c22789f8cb5af4f43ab260e5054254b007140818081c0a9c0b300d1c08100d1cf28de0050a0a038500830080455502100001a000000fd003090e6e63c010a202020202020000000fc003237474c3835300a2020202020000000ff003030354e544b46425a3538310a01a102031a7123090607e305c000e606050160592846100403011f13565e00a0a0a029503020350055502100001a909b0050a0a046500820880c555021000000b8bc0050a0a055500838f80c55502100001a00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000001a";
              };
              config = {
                "DP-2" = {
                  enable = true;
                  crtc = 1;
                  mode = "2560x1440";
                  position = "0x0";
                  rate = "144";
                  extraConfig = ''
                    x-prop-non_desktop 0
                  '';
                };
                "DP-4" = {
                  enable = true;
                  crtc = 0;
                  mode = "2560x1440";
                  position = "2560x0";
                  rate = "144.00";
                  extraConfig = ''
                    x-prop-non_desktop 0
                  '';
                };
              };
            };
          };
        };

        awscli = {
          enable = true;
          settings = {
            "default" = {
              "region" = "us-east-2";
            };
            "profile hydra-doom-admin" = {
              "sso_session" = "pi";
              "sso_account_id" = "509399595051";
              "sso_role_name" = "AWSAdministratorAccess";
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

        feh.enable = true;

        firefox.enable = true;

        fish = {
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
          plugins = with pkgs.fishPlugins; [
            {
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

        # Customized based on https://blog.gitbutler.com/how-git-core-devs-configure-git/
        git = {
          enable = true;
          userName = "Pi Lanningham";
          userEmail = "pi.lanningham@gmail.com";
          extraConfig = {
            init.defaultBranch = "main";
            branch.sort = "-committerdate";
            column.ui = "auto";
            commit.verbose = true;
            core = {
              editor = "vim";
              excludesfile = "~/.gitignore";
              fsmonitor = true;
              untrackedCache = true;
            };
            diff = {
              algorithm = "histogram";
              colorMoved = "plain";
              mnemonicPrefix = true;
              renames = true;
            };
            fetch = {
              prune = true;
              pruneTags = true;
              all = true;
            };
            help.autocorrect = "prompt";
            merge.conflictstyle = "zdiff3";
            push = {
              default = "simple";
              autoSetupRemote = true;
              followTags = true;
            };
            pull = {
              rebase = true;
            };
            rebase = {
              autoSquash = true;
              autoStash = true;
              updateRefs = true;
            };
            rerere = {
              enabled = true;
              autoupdate = true;
            };
            safe.directory = "/home/pi/flake";
            tag.sort = "version:refname";
            url."git@github.com:" = {
              insteadOf = "https://github.com";
            };
          };
        };

        ghostty = {
          enable = true;
          enableFishIntegration = true;
          settings = {
            font-family = "Fira Code";
            theme = "Hardcore";
            shell-integration-features = "sudo";
          };
        };

        go = {
          enable = true;
          env.GOPRIVATE = [
            "github.com/SundaeSwap-finance"
          ];
        };

        rofi = {
          enable = true;
          cycle = false;
          terminal = "\${pkgs.alacritty}/bin/alacritty";
          theme = "purple";
          plugins = [ pkgs.rofi-calc pkgs.rofi-emoji pkgs.rofi-power-menu pkgs.rofi-pulse-select ];
          extraConfig = {
            show-icons = true;
            icon-theme = "Papirus";
            hide-scrollbar = true;
            disable-history = false;
            auto-select = true;
            modes = [ "window" "drun" "calc" "emoji" ];
            hover-select = true;
            me-select-entry = "";
            me-accept-entry = [ "MousePrimary" ];
          };
        };

        vim = {
          enable = true;
        };

        vscode = {
          enable = true;
          # package = (pkgs.vscode.override{ isInsiders = true; }).overrideAttrs (oldAttrs: rec {
          #   src = (builtins.fetchTarball {
          #     url = "https://update.code.visualstudio.com/latest/linux-x64/insider";
          #     sha256 = "16vcginn0w22aciawibch0y7dibqfjbkik1nhs23x76abww1qkzv";
          #   });
          #   version = "latest";
          # });
        };
      };
    };
  };
}
