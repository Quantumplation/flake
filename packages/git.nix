{ ... }: {
  # Customized based on https://blog.gitbutler.com/how-git-core-devs-configure-git/
  programs.git = {
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
}
