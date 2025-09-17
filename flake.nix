{
  description = " ";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    vscode-server.url = "github:nix-community/nixos-vscode-server";
    rust-overlay.url = "github:oxalica/rust-overlay";
    rust-overlay.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = inputs @ {
    self,
    nixpkgs,
    home-manager,
    vscode-server,
    sops-nix,
    rust-overlay,
    ...
  }:
    let
      system = "x86_64-linux";
    in {
      nixosConfigurations = {
        pi = nixpkgs.lib.nixosSystem {
          inherit system;
          modules = [
            { nixpkgs.overlays = [ rust-overlay.overlays.default ]; }
            ./configuration.nix
            home-manager.nixosModules.home-manager
          ];
        };
      };
    };
}
