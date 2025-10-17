# packages/sops.nix
{ config, pkgs, ... }:

let
  pi = config.users.users.pi.name;
in
{
  # Install sops tools
  # environment.systemPackages = with pkgs; [
  #   sops
  #   age
  #   ssh-to-age
  # ];

  # SOPS configuration
  sops = {
    defaultSopsFile = ../secrets/secrets.yaml;
    validateSopsFiles = false;

    age = {
      sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
    };

    secrets = {
      "atuin/key" = {
        owner = pi;
        mode = "0400";
      };
      "atuin/session" = {
        owner = pi;
        mode = "0400";
      };
      "github/notifications" = {
        owner = pi;
        mode = "0400";
      };
      "wayvnc/password" = {
        owner = pi;
        mode = "0400";
      };
      "mercury/apiKey" = {
        owner = pi;
        mode = "0400";
      };
      "blockfrost/mainnet" = {
        owner = pi;
        mode = "0400";
      };
    };
  };
}
