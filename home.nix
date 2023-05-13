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
      };

      services = {
        flameshot = {
          enable = true;
          settings = {
            General = {
              contrastOpacity = 188;
              buttons = "@Variant(\\0\\0\\0\\x7f\\0\\0\\0\\vQList<int>\\0\\0\\0\\0\\x14\\0\\0\\0\\0\\0\\0\\0\\x2\\0\\0\\0\\x3\\0\\0\\0\\x5\\0\\0\\0\\x6\\0\\0\\0\\x12\\0\\0\\0\\xf\\0\\0\\0\\x16\\0\\0\\0\\x13\\0\\0\\0\\a\\0\\0\\0\\b\\0\\0\\0\\t\\0\\0\\0\\x10\\0\\0\\0\\n\\0\\0\\0\\v\\0\\0\\0\\r\\0\\0\\0\\x17\\0\\0\\0\\xe\\0\\0\\0\\f\\0\\0\\0\\x11)";
            };
          };
        };
        polybar = {
          enable = true;
          script = "$HOME/.config/polybar/launch.sh";
        };
        sxhkd = {
          enable = true;
          keybindings = {
            # Applications
            "super + a" = "alacritty";
            "super + b" = "firefox";
            "super + e" = "echo 'tbd'";
            "super + p" = "mypaint";
            
            # Close
	    "super + {_,shift + }w" = "bspc node -{c,k}";

            # Monocle mode
            "super + m" = "bspc desktop -l next";

            # Floating / tiled / fullscreen
            "super + {t,shift + t,s,f}" = "bspc node -t {tiled,pseud_tiled,floating,fullscreen}";

            # Move node between windows
            "super + alt + bracket{left, right}" = ''
               set NODE (bspc query -N -n focused); \
                 bspc node -m {prev,next}; \
                 bspc node -f $NODE
            '';
            # Move node between desktops
            "super + shift + bracket{left, right}" = "bspc node -d {next,prev}.local --follow";

            # Rotate or cylce nodes
            "super + {_, shift +}grave" = "bspc node @parent -R {90, 270}";
            "super + {_, shift +}Tab" = "bspc node @parent -C {backward,forward}";

            # Switch desktops
            "super + ctrl + {_,shift +}Tab" = "bspc desktop -f {next, prev}.local";

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

        firefox.enable = true;

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
  
        git = {
          enable = true;
          userName = "Pi Lanningham";
          userEmail = "pi.lanningham@gmail.com";
          extraConfig = {
            init.defaultBranch = "main";
            core.editor = "vim";
          };
        };
      };
    };
  };
}
