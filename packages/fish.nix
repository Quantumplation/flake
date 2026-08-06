{ pkgs, lib, ... }:

let
  # Package managers and build tools that execute arbitrary third-party code
  # (postinstall scripts, build.rs, setup.py) as part of normal operation.
  # These get transparently routed through the sbx sandbox so it is not
  # something you have to remember. Bypass any of them with `command <tool>`.
  #
  # Deliberately not wrapped: `go` (no dependency code runs at build time) and
  # `node`/`deno` (wrapping the runtime itself breaks far more than it protects
  # — the install step is where untrusted code actually executes).
  sandboxedTools = [
    "npm" "npx" "pnpm" "yarn"
    "bun" "bunx"
    "pip" "pip3" "uv" "uvx" "poetry"
    "cargo"
  ];

  sandboxWrappers = lib.genAttrs sandboxedTools (tool: {
    description = "${tool}, sandboxed via sbx (bypass: command ${tool})";
    # IN_SBX is set by sbx itself. The guard is belt-and-braces: the sandbox
    # gets a scratch $HOME so these autoloaded functions aren't present inside
    # it anyway, but this makes recursion impossible if that ever changes.
    body = ''
      if set -q IN_SBX
        command ${tool} $argv
      else
        sbx -- ${tool} $argv
      end
    '';
  });
in
{
  programs.fish = {
    enable = true;
    interactiveShellInit = ''
      set fish_greeting # Disable greeting
      ${pkgs.any-nix-shell}/bin/any-nix-shell fish --info-right | source

      function '?' --description 'Quick inline Claude with terminal context'
        set -l question (string join ' ' $argv)
        if test -z "$question"
          claude
          return
        end

        set -l hist (builtin history --max 50 | string collect)
        set -l git_branch (git branch --show-current 2>/dev/null; or echo 'not a git repo')
        set -l ctx "The user invoked you inline from their fish shell. You are running in print mode — complete the task fully and output a concise summary of what you did. Do not ask for clarification; make reasonable assumptions.

Working directory: $PWD
Git branch: $git_branch

Recent command history (most recent first):
$hist"

        # Route to the right model via quick haiku triage
        set -l model (claude -p --model haiku "Pick the best model for this task. Reply with ONLY one word.
- haiku: simple factual questions, quick lookups, short explanations
- sonnet: moderate tasks, code edits, debugging, multi-step reasoning
- opus: complex architecture, large refactors, subtle or ambiguous problems
Question: $question" 2>/dev/null | string trim | string lower)

        if not contains -- $model haiku sonnet opus
          set model sonnet
        end

        echo "→ $model"
        claude -p --model $model --append-system-prompt "$ctx" "$question"
      end
    '';
    shellInit = ''
      set -Ux NIX_LD /run/current-system/sw/share/nix-ld/lib/ld.so
      set -Ux NIX_LD_LIBRARY_PATH /run/current-system/sw/share/nix-ld/lib
      set -Ux LD_LIBRARY_PATH "${pkgs.stdenv.cc.cc.lib}/lib:${pkgs.openssl.out}/lib"
      set -Ux PKG_CONFIG_PATH "${pkgs.openssl.dev}/lib/pkgconfig:${pkgs.libsoup_3.dev}:${pkgs.glib.dev}:${pkgs.gobject-introspection.dev}"
      set -Ux GOPRIVATE github.com/SundaeSwap-finance
      set --global tide_right_prompt_items status cmd_duration node rustc go aws time
    '';
    shellAbbrs = {
      awslogin = "aws sso login --sso-session pi";
    };
    functions = sandboxWrappers // {
      nrs = {
        description = "NixOS rebuild switch with auto git-add";
        body = ''
          echo "Adding new files to git..."
          git -C ~/flake add -v .
          echo ""
          echo "Running nixos-rebuild..."
          sudo nixos-rebuild switch --flake ~/flake#(hostname | string lower)
        '';
      };
    };
    completions.tailscale-ssh = ''
      complete -c ssh -f -a "(tailscale status --json 2>/dev/null | ${pkgs.jq}/bin/jq -r '.Peer[] | .DNSName' | string replace -r '\\.\$' '''')"
    '';
    plugins = with pkgs.fishPlugins; [
      {
        # TODO: declarative tide config; remember to run tide configure when you first set this up
        name = "tide";
        src = pkgs.fetchFromGitHub {
          owner = "IlanCosman";
          repo = "tide";
          rev = "a34b0c2809f665e854d6813dd4b052c1b32a32b4";
          sha256 = "sha256-ZyEk/WoxdX5Fr2kXRERQS1U1QHH3oVSyBQvlwYnEYyc=";
        };
      }
    ];
  };
}
