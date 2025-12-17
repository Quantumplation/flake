{ pkgs, ... }: {
  programs.vim = {
    enable = true;
    packageConfigurable = pkgs.vim-full;
    defaultEditor = true;
  };
}
