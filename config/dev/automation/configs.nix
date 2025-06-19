let
  inherit (inputs) nixpkgs;
  inherit (inputs.std.dmerge) append;
  inherit (inputs.std.data) configs;
  inherit (inputs.std.lib.dev) mkNixago;
in
{
  treefmt = (mkNixago configs.treefmt) {
    data.formatter.prettier = {
      command = "prettier";
      excludes = [
        "./package.json"
        "./pnpm-lock.yaml"
      ];
      includes = append [ "*.mjs" ];
    };
    data.formatter.nix = {
      command = "nixpkgs-fmt";
    };
  };
  editorconfig = (mkNixago configs.editorconfig) { };
  conform = (mkNixago configs.conform) { };
  lefthook = (mkNixago configs.lefthook) { };

  cog = (mkNixago configs.cog) {
    data.changelog = {
      remote = "github.com";
      repository = "nix-dotfiles";
      owner = "ic4-y";
    };
  };
}
