{
  description = " ";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    hyprland.url = "github:hyprwm/Hyprland";
    hyprshell = {
      url = "github:H3rmt/hyprshell";
    };
    split-monitor-workspaces = {
      url = "github:Duckonaut/split-monitor-workspaces";
      inputs.hyprland.follows = "hyprland";
    };
    nix-colors.url = "github:misterio77/nix-colors";
    vscode-server.url = "github:nix-community/nixos-vscode-server";
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
    split-monitor-workspaces,
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
        # Desktop - Goldwasser (AMD + NVIDIA)
        goldwasser = nixpkgs.lib.nixosSystem {
          inherit system;
          specialArgs = { inherit inputs; };
          modules = [
            { nixpkgs.overlays = [ rust-overlay.overlays.default ]; }
            home-manager.nixosModules.home-manager
            sops-nix.nixosModules.sops
            ./hosts/goldwasser
          ];
        };

        # Legacy alias for backwards compatibility (remove after confirming rebuild works)
        pi = nixpkgs.lib.nixosSystem {
          inherit system;
          specialArgs = { inherit inputs; };
          modules = [
            { nixpkgs.overlays = [ rust-overlay.overlays.default ]; }
            home-manager.nixosModules.home-manager
            sops-nix.nixosModules.sops
            ./hosts/goldwasser
          ];
        };

        # Future: Laptop - Noether (Intel/AMD graphics)
        # noether = nixpkgs.lib.nixosSystem {
        #   inherit system;
        #   specialArgs = { inherit inputs; };
        #   modules = [
        #     { nixpkgs.overlays = [ rust-overlay.overlays.default ]; }
        #     home-manager.nixosModules.home-manager
        #     sops-nix.nixosModules.sops
        #     ./hosts/noether/configuration.nix
        #   ];
        # };
      };
    };
}
