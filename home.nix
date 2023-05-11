{ config, lib, pkgs, ... }:

{
  home = {
    username = "pi";
    homeDirectory = "/home/pi";
    stateVersion = "22.11";

    packages = with pkgs; [
    ];
  };

  programs = {
    home-manager.enable = true;
    fish = {
      enable = true;
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
}
