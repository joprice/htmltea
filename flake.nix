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
      defaultPackage = packages.htmltea;
      packages = {
        htmltea = buildDunePackage
          {
            version = builtins.trace (self.sourceInfo) "0.0.1";
            pname = "htmltea";
            src = ./.;
            buildInputs = [
              curly
              lambdasoup
              ocaml_pcre
            ];
          };
        installPhase = ''
          mkdir -p $out/bin
          mv _build/default/bin/htmltea.exe $out/bin/htmltea
        '';
      };
      devShells. default = mkShell
        {
          inputsFrom = [ packages.htmltea ];
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
