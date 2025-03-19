{
  description = "A flake for building development shells";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    mk-minimal-shell.url = "github:n-hass/mk-minimal-shell";
  };

  outputs =
    {
      self,
      nixpkgs,
      mk-minimal-shell,
    }:
    let
      myLib = import ./lib.nix { };
    in {
      mkMiniDevShell =
        argThunk:
        (myLib.forAllSystems (
          system:
          let
            requiredPkgs = import nixpkgs {
              inherit system;
              overlays = [
                mk-minimal-shell.overlay
                self.overlay
              ];
            };
            uncheckedArgs = argThunk system requiredPkgs;
            extraFlakeOutputs = uncheckedArgs.extraFlakeOutputs or { };
            args = {
              pkgs = requiredPkgs;
            } // uncheckedArgs;
            pkgs = args.pkgs;
            lib = pkgs.lib;
            shellArgs = args // {
              extraFlakeOutputs = null;
              pkgs = null;
            };
          in
          (lib.recursiveUpdate {
            devShells =
              let
                shell = myLib.mkCustomShell pkgs.mkMinimalShell shellArgs pkgs;
              in
              {
                default =
                  let
                    result =
                      lib.warnIf (!(pkgs ? mkMinimalShell))
                        "mkMinimalShell is missing! If you've overriden pkgs, ensure that it's provided as pkgs.mkMinimalShell."
                        shell;
                  in
                  result;
              };
          } extraFlakeOutputs)
        ));
      lib = myLib;
      overlay = (import ./overlay.nix { inherit mk-minimal-shell; }).overlay;
    };
}
