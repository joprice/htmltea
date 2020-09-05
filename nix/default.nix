{ pkgs }:

with pkgs;
let
  ocaml = ocaml-ng.ocamlPackages_4_10.ocaml;
  opam2nix = import ./opam2nix.nix {
    ocamlPackagesOverride = ocaml-ng.ocamlPackages_4_10;
  };
  args = {
    inherit ocaml;
    selection = ./opam-selection.nix;
    src = ../.;
  };
  resolve = opam2nix.resolve args [
    "htmltea.opam"
  ];
  selection = opam2nix.build args;
in
{
  inherit opam2nix pkgs resolve;
  inherit (selection) htmltea;
}
