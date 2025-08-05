{ pkgs ? import <nixpkgs> {} }:

let
  lenovo-wwan-unlock = pkgs.callPackage ./default.nix {};
in
pkgs.mkShell {
  buildInputs = [ lenovo-wwan-unlock ];

  shellHook = ''
    echo "lenovo-wwan-unlock package built and available"
  '';
}