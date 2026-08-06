{ pkgs, osConfig, ... }: {
  programs.atuin = {
    enable = true;
    # Pinned to 18.13.6 — newer versions have a bug preventing recent results from showing.
    package = pkgs.atuin.overrideAttrs (finalAttrs: _prev: {
      version = "18.13.6";
      src = pkgs.fetchFromGitHub {
        owner = "atuinsh";
        repo = "atuin";
        tag = "v18.13.6";
        hash = "sha256-yAw+ty6FUnFbiRTdAe2QQHzj6uU24fZ/bEIXcHl/thg=";
      };
      cargoDeps = pkgs.rustPlatform.fetchCargoVendor {
        inherit (finalAttrs) src;
        name = "atuin-18.13.6-vendor";
        hash = "sha256-jirVe0+N5+UHZWioj8AipUhawMBameqEJJpa8HPTnfw=";
      };
    });
    settings = {
      show_preview = true;
      invert = false;
      inline_height = 10;
      style = "auto";
      enter_accept = true;
      sync_address = "https://api.atuin.sh";
      # sops is a NixOS-level module, so the secret paths come from osConfig
      key_path = osConfig.sops.secrets."atuin/key".path;
      session_path = osConfig.sops.secrets."atuin/session".path;
    };
  };
}
