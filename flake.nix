{
  description = "";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    home-manager = {
      url = github:nix-community/home-manager;
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, home-manager, ... }:
    let
      system = "x86_64-linux";
      lib = nixpkgs.lib;
     #pkgs = import inputs.nixpkgs {
     #  overlays = [
     #    (final: prev: {
     #      plymouth-themes = final.callPackage pkgs.adi1090x-plymouth-themes { selected_themes = ["circle"]; };
     #    })
     #  ]
     #};
    in {
      nixosConfigurations = {
        pi = lib.nixosSystem {
          inherit system;
          modules = [
            ./configuration.nix
            home-manager.nixosModules.home-manager
          ];
        };
      };
    };
}
