let
  default = (import ./default.nix { });
  pkgs = default.pkgs;
  ocp-browser = pkgs.writeShellScript "ocp" ''
    set -euo pipefail
    OCP_BROWSER_PATH=$(echo $OCAMLPATH | tr ':' ',')
    ocp-browser -I "$OCP_BROWSER_PATH" "$@"
  '';
  odig-data = "$HOME/.cache/odig-data";
  odig-update = pkgs.writeShellScript "odig-update" ''
    # https://github.com/b0-system/odig/issues/48
    odig_data=${odig-data}
    mkdir -p $odig_data

    # TODO: turn into derivation, only run if deps have changed
    IFS=':' read -ra folders <<< "$OCAMLPATH"
    for i in ''${folders[@]}; do
      for sub in $i/*; do
        lib=$(basename $sub)
        if [[ "$lib" != "stublibs" && "$lib" != "core_kernel" ]]; then
          rm -rf $odig_data/$lib
          ln -sF $sub $odig_data/$lib
        fi
      done
    done
    #odig doc -u
  '';
  ocp = pkgs.stdenv.mkDerivation {
    name = "ocp";
    phases = [ "installPhase" ];
    installPhase = ''
      mkdir -p $out/bin/
      cp ${ocp-browser} $out/bin/ocp
      cp ${odig-update} $out/bin/odig-update
    '';
  };
  inputs = (drv: (drv.buildInputs or [ ]) ++
    (drv.propagatedBuildInputs or [ ])
  );
in
pkgs.stdenv.mkDerivation
{
  name = "eventual-shell";
  buildInputs = [
    ocp
    pkgs.python3
    (inputs default.htmltea)
  ];
  # NOTE: direnv doesn't support aliases or defining functoins, so I'm trying to 
  # duplicate that logic above.
  # See https://github.com/direnv/direnv/issues/73#issuecomment-174295790
  shellHook = ''
    set -eu

    #OCP_BROWSER_PATH=$(echo $OCAMLPATH | tr ':' ',')
    #alias ocp-browser="ocp-browser -I $OCP_BROWSER_PATH"
    #function ocp() {
    #  "ocp-browser -I $OCP_BROWSER_PATH" "$@"
    #}

    #odig-update

    export ODIG_CACHE_DIR="$HOME/.cache/odig"
    export ODIG_LIB_DIR=${odig-data}
  '';
}
