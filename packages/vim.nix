{ pkgs, ... }: {
  programs.vim = {
    enable = true;
    packageConfigurable = pkgs.vim_configurable;
    defaultEditor = true;
  };
}
