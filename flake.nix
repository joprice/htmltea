{
  description = "htmltea";
  inputs = {
    nix-filter.url = "github:numtide/nix-filter";
    flake-utils.url = "github:numtide/flake-utils";
    nixpkgs = {
      url = "github:nix-ocaml/nix-overlays";
      inputs.flake-utils.follows = "flake-utils";
    };
  };
  outputs =
    { self
    , nixpkgs
    , flake-utils
    , nix-filter
    }:
    flake-utils.lib.eachDefaultSystem (system:
    let
      pkgs = nixpkgs.legacyPackages.${system}.extend (_: super: {
        ocamlPackages = super.ocaml-ng.ocamlPackages_5_1;
      });
    in
    with pkgs;
    with ocamlPackages;
    rec {
      devShells. default = mkShell
        {
          propagatedBuildInputs = [
            curly
            lambdasoup
          ];
          nativeBuildInputs = [
            findlib
          ];
          buildInputs = [
            dune_3
            ocaml
            ocaml-lsp
            ocamlformat
            pkg-config
          ];
          OCAMLRUNPARAM = "b";
        };
    });
}
