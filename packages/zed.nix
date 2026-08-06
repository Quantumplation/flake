{ pkgs, ... }: {
  home.packages = with pkgs; [
    zed-editor
  ];

  xdg.configFile."zed/settings.json".text = builtins.toJSON {
    vim_mode = true;
    features = {
      edit_prediction_provider = "none";
    };
    theme = {
      mode = "dark";
      dark = "Tokyo Night";
      light = "Tokyo Night Light";
    };
    project_panel = {
      dock = "right";
    };
    lsp = {
      tinymist = {
        # Runs a preview server at http://127.0.0.1:23635 that follows the
        # focused .typ file; open it in a browser next to Zed.
        #
        # Do NOT set `args` here: Zed applies these initialization_options
        # twice (once via the extension's settings passthrough, once on its
        # own) and concatenates arrays when merging, so tinymist would be
        # handed `--data-plane-host` twice and refuse to start the preview.
        # The defaults are 127.0.0.1:23635 with --invert-colors=auto anyway.
        initialization_options = {
          preview.background.enabled = true;
        };
        settings = {
          formatterMode = "typstyle";
        };
      };
    };
    languages = {
      Typst = {
        soft_wrap = "editor_width";
      };
    };
  };
}
