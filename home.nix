{ config, lib, pkgs, ... }:

{
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
        flameshot.enable = true;
        sxhkd = {
          enable = true;
          keybindings = {
            "super + a" = "alacritty";
            "super + b" = "firefox";
            "super + e" = "echo 'tbd'";
            "super + p" = "mypaint";
            
	    "super + {_,shift + }w" = "bspc node -{c,k}";

            "super + m" = "bspc desktop -l next";
            "super + {t,shift + t,s,f}" = "bspc node -t {tiled,pseud_tiled,floating,fullscreen}";

            "super + alt + bracket{left, right}" = "set NODE (bspc query -N -n focused); bspc node -m {prev,next}; bspc node -f $NODE";
            "super + shift + bracket{left, right}" = "bspc node -d {next,prev}.local --follow";
            "super + {_, shift +}Tab" = "bspc node @parent -C {backward,forward}";

            "swap + ctrl + {_,shift +}Tab" = "bspc desktop -f {next, prev}.local";

            "alt + button{1-3}" = "bspc pointer -g {move,resize_side,resize_corner}";
            "alt + !button{1-3}" = "bspc pointer -t %i, %i";
            "alt + @button{1-3}" = "bspc pointer -u";

            # 2 extra spaces required for proper formatting
            "ctrl + shift + 4" = ''
               mkdir -p ~/Pictures/Captures/$(date +"%Y-%m"); \
                 flameshot gui -p ~/Pictures/Captures/$(date +"%Y-%m")/
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
