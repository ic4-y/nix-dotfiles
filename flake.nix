{
  description = "System Flake";

  inputs = {
    nixpkgs.url = "nixpkgs/nixos-25.05";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager/release-25.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixvim.url = "github:ic4-y/nixvim-config";
    nixvim.inputs.nixpkgs.follows = "nixpkgs-unstable";

    nixpak.url = "github:nixpak/nixpak";
    nixpak.inputs.nixpkgs.follows = "nixpkgs";

    sops-nix.url = "github:Mic92/sops-nix";
    sops-nix.inputs.nixpkgs.follows = "nixpkgs";

    disko.url = "github:nix-community/disko/latest";
    disko.inputs.nixpkgs.follows = "nixpkgs";

    impermanence.url = "github:nix-community/impermanence";
    impermanence.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { self, nixpkgs, nixvim, nixpak, nixpkgs-unstable, home-manager, disko, impermanence, ... }@inputs:
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

      overlay-tooling = (final: prev: {
        specify-cli = final.callPackage ./pkgs/specify-cli { };
        bmad-method = final.callPackage ./pkgs/bmad-method { };
        openspec = final.callPackage ./pkgs/openspec { };
      });

      overlay-custom = import ./packages;

      # Create pkgs with tooling overlays for devShell
      pkgsWithTooling = import nixpkgs {
        inherit system;
        config = { allowUnfree = true; };
        overlays = [ overlay-unstable overlay-tooling ];
      };
    in
    {
      devShells.${system}.default = pkgsWithTooling.mkShell {
        buildInputs = with pkgsWithTooling; [
          # Git + core tooling
          git
          lefthook
          treefmt

          # BMAD / workflow tooling
          specify-cli
          bmad-method
          openspec

          # Commit message + secret scanning tooling
          conform
          ripsecrets

          # Nix tooling & LSP
          nixpkgs-fmt
          nixd
        ];

        shellHook = ''
          echo "[aenaos-core] Nix dev shell loaded:"
          echo "  - Nix tooling (nixpkgs-fmt, nixd)"
          echo "  - Agentic A.I. tooling (bmad-method, specify-cli, openspec)"
          echo "  - Lefthook available for git hooks"
        '';
      };

      nixosConfigurations = {
        archon = lib.nixosSystem {
          inherit system;
          specialArgs = { inherit inputs nixpak; }; # Pass all inputs and nixpak as specialArgs
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
            (import ./config/hosts/archon-home.nix { inherit pkgs inputs system; })
          ];
        };

        ap-perseus = home-manager.lib.homeManagerConfiguration {
          inherit pkgs;
          modules = [
            {
              nixpkgs.overlays = [ overlay-unstable overlay-custom ];
            }
            (import ./config/hosts/perseus-home.nix { inherit pkgs inputs system; })
          ];
        };

        ap-cadmus = home-manager.lib.homeManagerConfiguration {
          inherit pkgs;
          modules = [
            {
              nixpkgs.overlays = [ overlay-unstable overlay-custom ];
            }
            (import ./config/hosts/cadmus-home.nix { inherit pkgs inputs system; })
          ];
        };
      };

      nixosModules = {
        disko-test = ./config/sys/modules/hardware/disko-test.nix;
        impermanence = ./config/sys/modules/impermanence.nix;
      };

      checks.x86_64-linux = {
        disko-btrfs-test = import ./tests/disko-btrfs-test.nix {
          inherit pkgs self lib disko impermanence;
        };
      };
    };
}
