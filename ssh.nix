{ config, lib, pkgs, ... }:

{
  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
    matchBlocks = {
      "mainnet-sundae-gd-0" = {
        hostname = "10.0.102.113";
        user = "ec2-user";
        proxyCommand = "ssh ec2-user@mainnet-sundae-gd-prometheus -W %h:%p";
      };
      "mainnet-sundae-gd-1" = {
        hostname = "10.0.104.156";
        user = "ec2-user";
        proxyCommand = "ssh ec2-user@mainnet-sundae-gd-prometheus -W %h:%p";
      };
      "*" = {
        forwardAgent = true;
        addKeysToAgent = "yes";
        serverAliveInterval = 0;
        compression = false;
        controlMaster = "no";
        setEnv = {
          TERM = "xterm-256color";
        };
      };
    };
  };
}
