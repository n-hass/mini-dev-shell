{
  description = "A flake for building development shells";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    mk-minimal-shell.url = "github:n-hass/mkminimalshell";
  };

  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
      mk-minimal-shell,
    }:
    {
      mkMiniDevShell =
        argThunk:
        (flake-utils.lib.eachDefaultSystem (
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
            myLib = import ./lib.nix { };
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
      lib = import ./lib.nix { };
      overlay = (import ./overlay.nix { inherit mk-minimal-shell; }).overlay;
    };
}
