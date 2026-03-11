{
  description = " ";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nixos-hardware.url = "github:nixos/nixos-hardware/master";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    hyprland.url = "github:hyprwm/Hyprland";
    hyprshell = {
      url = "github:H3rmt/hyprshell";
      inputs.hyprland.follows = "hyprland";
    };
nix-colors.url = "github:misterio77/nix-colors";
rust-overlay.url = "github:oxalica/rust-overlay";
    rust-overlay.inputs.nixpkgs.follows = "nixpkgs";
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs @ {
    self,
    nixpkgs,
    hyprland,
    hyprshell,
    home-manager,
    sops-nix,
    rust-overlay,
    ...
  }:
    {
      nixosConfigurations = {
        # Desktop - Goldwasser (AMD + NVIDIA)
        goldwasser = nixpkgs.lib.nixosSystem {
          specialArgs = { inherit inputs; };
          modules = [
            { nixpkgs.hostPlatform = "x86_64-linux"; }
            { nixpkgs.overlays = [ rust-overlay.overlays.default ]; }
            home-manager.nixosModules.home-manager
            sops-nix.nixosModules.sops
            ./hosts/goldwasser
          ];
        };

        # Laptop - Noether (Framework 16, AMD)
        noether = nixpkgs.lib.nixosSystem {
          specialArgs = { inherit inputs; };
          modules = [
            { nixpkgs.hostPlatform = "x86_64-linux"; }
            { nixpkgs.overlays = [ rust-overlay.overlays.default ]; }
            home-manager.nixosModules.home-manager
            sops-nix.nixosModules.sops
            ./hosts/noether
          ];
        };
      };
    };
}
