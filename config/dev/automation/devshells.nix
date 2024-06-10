let
  inherit (inputs.nixpkgs) pkgs;
  inherit (inputs.std) std;
  inherit (inputs.std.lib) dev;
  inherit (cell) configs;
in
{
  default = dev.mkShell {
    name = "NixOS configurations devShell";
    imports = [ std.devshellProfiles.default ];
    commands = [
      { package = pkgs.nil; }
      { package = pkgs.nixpkgs-fmt; }
      { package = pkgs.sops; }
      { package = pkgs.age; }
    ];
    nixago = [
      configs.conform
      configs.treefmt
      configs.editorconfig
      configs.lefthook
      configs.cog
    ];
  };
}
