{
  config,
  pkgs,
  ...
}: {
  home.file = {
    ".config/wofi/style.css" = {
      text = ''
        /* Polish spec: spacing 4/8/12/16, radius surface=12 control=8 */

        * {
          font-family: 'CaskaydiaMono Nerd Font', monospace;
          font-size: 14px;
        }

        window {
          margin: 0;
          padding: 0;
          background-color: #${config.colorScheme.palette.base00}b3;
          border: 1px solid rgba(255, 255, 255, 0.06);
          border-radius: 12px;
        }

        #outer-box {
          margin: 0;
          padding: 12px;
          border: none;
          background-color: transparent;
        }

        #inner-box {
          margin: 0;
          padding: 0;
          border: none;
          background-color: transparent;
        }

        #scroll {
          margin: 0;
          padding: 0;
          border: none;
          background-color: transparent;
        }

        #input {
          margin: 0 0 8px 0;
          padding: 12px 16px;
          border: 1px solid rgba(255, 255, 255, 0.06);
          border-radius: 8px;
          background-color: rgba(0, 0, 0, 0.2);
          color: #${config.colorScheme.palette.base05};
          font-size: 16px;
        }

        #input:focus {
          outline: none;
          box-shadow: none;
          border: 1px solid #${config.colorScheme.palette.base0D};
        }

        #text {
          margin: 0 8px;
          border: none;
          color: #${config.colorScheme.palette.base05};
        }

        #entry {
          padding: 8px;
          border-radius: 8px;
          background-color: transparent;
        }

        #entry:selected {
          outline: none;
          border: none;
          background-color: rgba(255, 255, 255, 0.06);
        }

        #entry:selected #text {
          color: #${config.colorScheme.palette.base07};
        }

        #entry image {
          -gtk-icon-transform: scale(0.7);
        }
      '';
    };
  };

  programs.wofi = {
    enable = true;
    settings = {
      width = 600;
      height = 350;
      location = "center";
      show = "drun";
      prompt = "Search...";
      filter_rate = 100;
      allow_markup = true;
      no_actions = true;
      halign = "fill";
      orientation = "vertical";
      content_halign = "fill";
      insensitive = true;
      allow_images = true;
      image_size = 40;
      gtk_dark = true;
    };
  };
}
