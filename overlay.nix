{ mk-minimal-shell, ... }:

{
  overlay =
    final: prev:
    let
      baseMkMinimalShell = mk-minimal-shell.overlay final prev;
      pkgs = final.pkgs;
      mkShell = baseMkMinimalShell.mkMinimalShell;
      myLib = import ./lib.nix { };
    in
    {
      mkMiniDevShell = args: (myLib.mkCustomShell mkShell args pkgs);
    };
}
