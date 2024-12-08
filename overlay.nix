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
      mkMiniDevShell = args: let 
        pkgsActual = if (args ? pkgs) then args.pkgs else pkgs;
        argsClean = args // { pkgs = null; };
      in (myLib.mkCustomShell mkShell argsClean pkgsActual);
    };
}
