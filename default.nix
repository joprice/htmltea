{ pkgs ? import
    (fetchTarball {
      # 08-28-2020
      url = "https://github.com/NixOS/nixpkgs/archive/000bb5ee45e3fa0339ccf64f33a2959c553aeab1.tar.gz";
      #sha256 = "";
    })
    { }
}:
pkgs.callPackage ./nix { }
