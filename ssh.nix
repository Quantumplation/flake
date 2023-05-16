{ config, lib, pkgs, ... }:

{
  home-manager.users.pi.programs.ssh = {
    enable = true;
    matchBlocks = {
    };
  };
}
