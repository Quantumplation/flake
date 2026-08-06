{ config, lib, pkgs, ... }:

let
  # Flip to true AFTER completing the 1Password setup (see NOTE below). Until
  # then ssh keeps using the plain ssh-agent and the on-disk key in ~/.ssh.
  #
  # NOTE — manual steps, they cannot be done from Nix:
  #   1. 1Password GUI → Settings → Developer → "Use the SSH agent"
  #   2. Import ~/.ssh/id_ed25519 into the vault as an SSH Key item, then
  #      shred the on-disk copy (the .pub can stay).
  #   3. Settings → Developer → Security → require approval per use, so a
  #      process running as you can *use* the key only with a visible prompt
  #      and can never *read* it.
  #   4. Flip this to true, rebuild, then set programs.ssh.startAgent = false
  #      in modules/programs.nix so the two agents don't race for SSH_AUTH_SOCK.
  useOnePasswordAgent = false;

  # Agent forwarding exposes your agent socket to root on the remote host for
  # the life of the connection — they can authenticate as you, anywhere, while
  # you are connected. So it is off by default and enabled per host.
  #
  # Not enabled on relay1/relay2/bp: those are internet-facing Cardano relays
  # and the block producer, i.e. the hosts most likely to be compromised and
  # the ones with the least need to authenticate outward as you.
  forward = { ForwardAgent = true; };
in
{
  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
    settings = {
      "mainnet-sundae-gd-0" = forward // {
        HostName = "10.0.102.113";
        User = "ec2-user";
        ProxyCommand = "ssh ec2-user@mainnet-sundae-gd-prometheus -W %h:%p";
      };
      "mainnet-sundae-gd-1" = forward // {
        HostName = "10.0.104.156";
        User = "ec2-user";
        ProxyCommand = "ssh ec2-user@mainnet-sundae-gd-prometheus -W %h:%p";
      };
      # Catches the other Sundae boxes reachable over Tailscale (including the
      # mainnet-sundae-gd-prometheus jump host). Sorts before the two specific
      # blocks above and sets only ForwardAgent, so it shadows nothing.
      "mainnet-sundae-*" = forward;

      "relay1" = {
        HostName = "164.92.82.145";
        User = "pi";
        Port = 9265;
      };
      "relay2" = {
        HostName = "164.92.90.119";
        User = "pi";
        Port = 9265;
      };
      "bp" = {
        HostName = "147.182.254.166";
        User = "pi";
        Port = 9265;
      };
      "Goldwasser" = forward // {
        HostName = "100.76.247.80";
        User = "pi";
      };

      "*" = {
        ForwardAgent = false;
        AddKeysToAgent = "yes";
        ServerAliveInterval = 0;
        Compression = false;
        ControlMaster = "no";
        SetEnv = {
          TERM = "xterm-256color";
        };
      } // lib.optionalAttrs useOnePasswordAgent {
        # Keys live in the 1Password vault, not on disk. The agent signs on
        # request and (with per-use approval enabled) prompts every time, so
        # code running as you cannot exfiltrate the key material itself.
        IdentityAgent = "~/.1password/agent.sock";
      };
    };
  };
}
