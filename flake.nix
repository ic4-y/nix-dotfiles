{
  description = "System Flake";

  inputs = {
    nixpkgs.url = "nixpkgs/nixos-24.05";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager/release-24.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    hyprland = {
      url = "github:hyprwm/Hyprland/7ba2c31"; #7ba2c31
      inputs.nixpkgs.follows = "nixpkgs-unstable";
    };

    nixvim.url = "github:icodeforyou-dot-net/nixvim-config";
    nixvim.inputs.nixpkgs.follows = "nixpkgs-unstable";

    sops-nix.url = "github:Mic92/sops-nix";
    sops-nix.inputs.nixpkgs.follows = "nixpkgs";

    std = {
      url = "github:divnix/std";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        devshell.url = "github:numtide/devshell";
        nixago.url = "github:nix-community/nixago";
      };
    };
  };

  outputs = { std, self, nixpkgs, nixvim, nixpkgs-unstable, home-manager, hyprland, ... }@inputs:
    let
      system = "x86_64-linux";

      pkgs = import nixpkgs {
        inherit system;
        config = {
          allowUnfree = true;
        };
      };

      lib = nixpkgs.lib;

      overlay-unstable = final: prev: {
        unstable = import nixpkgs-unstable {
          system = "x86_64-linux";
          config.allowUnfree = true;
        };
      };

      overlay-custom = import ./packages;
    in
    std.growOn
      {
        inherit inputs;
        nixpkgsConfig.allowUnfree = true;
        systems = [ "x86_64-linux" ];
        cellsFrom = ./config/dev;
        cellBlocks = with std.blockTypes; [
          (nixago "configs")
          (devshells "devshells")
        ];
      }
      # std soil for standard nixosConfigs homeConfigs and classical devShells
      {
        nixosConfigurations = {
          archon = lib.nixosSystem {
            inherit system;
            modules = [
              ./config/hosts/archon-system.nix
              {
                nix = {
                  registry.nixpkgs.flake = nixpkgs;
                  nixPath = [ "nixpkgs=${nixpkgs}" ];
                  settings.trusted-users = [ "root" "@wheel" ];
                };
              }
              { nixpkgs.overlays = [ overlay-unstable overlay-custom ]; }
            ];
          };

          perseus = lib.nixosSystem {
            inherit system;
            modules = [
              ./config/hosts/perseus-system.nix
              {
                nix.registry.nixpkgs.flake = nixpkgs;
                nix.nixPath = [ "nixpkgs=${nixpkgs}" ];
                nix.settings.trusted-users = [ "root" "@wheel" ];
              }
              { nixpkgs.overlays = [ overlay-unstable overlay-custom ]; }
            ];
          };

          cadmus = lib.nixosSystem {
            inherit system;
            modules = [
              ./config/hosts/cadmus-system.nix
              {
                nix.registry.nixpkgs.flake = nixpkgs;
                nix.nixPath = [ "nixpkgs=${nixpkgs}" ];
                nix.settings.trusted-users = [ "root" "@wheel" ];
              }
              { nixpkgs.overlays = [ overlay-unstable overlay-custom ]; }
            ];
          };

        };

        homeConfigurations = {

          ap-archon = home-manager.lib.homeManagerConfiguration {
            inherit pkgs;
            modules = [
              {
                nixpkgs.overlays = [ overlay-unstable overlay-custom ];
              }
              (import ./config/hosts/archon-home.nix { inherit inputs system; })
            ];
          };

          ap-perseus = home-manager.lib.homeManagerConfiguration {
            inherit pkgs;
            modules = [
              {
                nixpkgs.overlays = [ overlay-unstable overlay-custom ];
              }
              (import ./config/hosts/perseus-home.nix { inherit inputs system; })
            ];
          };

          ap-cadmus = home-manager.lib.homeManagerConfiguration {
            inherit pkgs;
            modules = [
              {
                nixpkgs.overlays = [ overlay-unstable overlay-custom ];
              }
              (import ./config/hosts/cadmus-home.nix { inherit inputs system; })
            ];
          };
        };
      };
}
