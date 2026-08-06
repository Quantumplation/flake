{ pkgs, ... }: {
  nix = {
    package = pkgs.nixVersions.stable;
    extraOptions = "experimental-features = nix-command flakes ca-derivations";

    settings = {
      auto-optimise-store = true;

      # A substituter can serve arbitrary content for any store path it has a
      # trusted signature for — the hash in the path is not re-verified against
      # a local build. Trusting a cache is therefore equivalent to granting that
      # organisation root on this machine. Only cache.nixos.org gets that by
      # default; everything else is opt-in per project (see trusted-substituters).
      substituters = [ "https://cache.nixos.org" ];

      # Cardano-ecosystem caches. Listing them here does NOT enable them — it
      # only permits a non-trusted user to opt in for a specific invocation:
      #
      #   nix build --option extra-substituters https://cache.iog.io
      #
      # or permanently for one project, via `nixConfig.extra-substituters` in
      # that project's own flake.nix. Without this list, dropping "pi" from
      # trusted-users below would make those opt-ins silently ignored.
      trusted-substituters = [
        "https://iohk.cachix.org"
        "https://cache.iog.io"
        "https://public-plutonomicon.cachix.org"
      ];

      trusted-public-keys = [
        "iohk.cachix.org-1:DpRUyj7h7V830dp/i6Nti+NEO2/nhblbov/8MW7Rqoo="
        "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
        "cache.iog.io:f/Ea+s+dFdN+3Y/G+FDgSq+a5NEWhJGzdjvKNGv0/EQ="
        "public-plutonomicon.cachix.org-1:3AKJMhCLn32gri1drGuaZmFrmnue+KkKrhhubQk/CWc="
      ];

      # Deliberately NOT "pi". A trusted user can tell the daemon to pull from
      # an arbitrary substituter with signature checking disabled, which is a
      # silent, unprompted path to root-owned content in the store. That is
      # reachable by anything running as pi — an npm postinstall, a compromised
      # editor extension — which is exactly the threat this config is about.
      # For the rare operation that genuinely needs it, use `sudo nix ...`.
      trusted-users = [ "root" ];
      allowed-users = [ "root" "pi" ];
      access-tokens = [];
    };

    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 7d";
    };
  };
}
