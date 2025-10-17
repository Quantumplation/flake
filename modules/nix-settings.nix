{ pkgs, ... }: {
  nix = {
    package = pkgs.nixVersions.stable;
    extraOptions = "experimental-features = nix-command flakes ca-derivations";

    settings = {
      auto-optimise-store = true;

      substituters = [
        "https://cache.nixos.org"
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

      trusted-users = [ "root" "pi" ];
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
