{ config, lib, pkgs, ... }:

{
  imports = [
    ./polybar/default.nix
  ];

  home-manager = {
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
      };

      xsession.windowManager.bspwm = {
        enable = true;
        settings = {
          border_width = 2;
          window_gap = 18;

          split_ratio = 0.52;
          borderless_monocle = true;
          gapless_monocle = true;

          focused_border_color = "#a6bc69";
        };
        monitors = {
          DP-2 = [ "A" "B" ];
          DP-3-8 = [ "C" "D" ];
        };
        startupPrograms = [
          "systemctl --user restart polybar"
          "xsetroot -cursor_name left_ptr"
          "betterlockscreen -w blur 0.5"
        ];
      };

      services = {
        autorandr.enable = false;
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
              browser = "${pkgs.firefox}/bin/firefox";
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
              buttons = "@Variant(\\0\\0\\0\\x7f\\0\\0\\0\\vQList<int>\\0\\0\\0\\0\\x14\\0\\0\\0\\0\\0\\0\\0\\x2\\0\\0\\0\\x3\\0\\0\\0\\x5\\0\\0\\0\\x6\\0\\0\\0\\x12\\0\\0\\0\\xf\\0\\0\\0\\x16\\0\\0\\0\\x13\\0\\0\\0\\a\\0\\0\\0\\b\\0\\0\\0\\t\\0\\0\\0\\x10\\0\\0\\0\\n\\0\\0\\0\\v\\0\\0\\0\\r\\0\\0\\0\\x17\\0\\0\\0\\xe\\0\\0\\0\\f\\0\\0\\0\\x11)";
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
            refresh-rate = 0;
            dbe = false;
            paint-on-overlay = true;
            sw-opti = true;
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
            "super + a" = "alacritty";
            "super + b" = "firefox";
            "super + e" = "rofi -show file-browser-extended -file-browser-depth 3";
            "super + shift + e" = "thunar";
            "super + n" = "code";
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
  
      programs = {
        home-manager.enable = true;

        alacritty = {
          enable = true;
          settings = {
            window = {
              decorations = "full";
              opacity = 0.85;
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

        autorandr = {
          enable = true;
        };

        feh.enable = true;

        firefox.enable = true;

        fish = {
          enable = true;
          interactiveShellInit = ''
            set fish_greeting # Disable greeting
          '';
          plugins = with pkgs.fishPlugins; [
            { name = "pisces"; src = pisces; }
            { name = "tide"; src = tide; }
          ];
        };

        git = {
          enable = true;
          userName = "Pi Lanningham";
          userEmail = "pi.lanningham@gmail.com";
          extraConfig = {
            init.defaultBranch = "main";
            core.editor = "vim";
            safe.directory = "/home/pi/flake";
          };
        };

        go.enable = true;

        rofi = {
          enable = true;
          cycle = false;
          terminal = "\${pkgs.alacritty}/bin/alacritty";
          theme = "purple";
          plugins = [ pkgs.rofi-calc pkgs.rofi-emoji pkgs.rofi-power-menu pkgs.rofi-pulse-select pkgs.rofi-file-browser ];
          extraConfig = {
            show-icons = true;
            icon-theme = "Papirus";
            hide-scrollbar = true;
            disable-history = false;
            auto-select = true;
            modes = [ "window" "file-browser-extended" "drun" "calc" "emoji" ];
            hover-select = true;
            me-select-entry = "";
            me-accept-entry = [ "MousePrimary" ];
          };
        };

        vscode = {
          enable = true;
        };
      };
    };
  };
}
