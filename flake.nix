{
  description = "A flake for building development shells with both mkMiniDevShell and an additive flake-parts module";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    mk-minimal-shell.url = "github:n-hass/mk-minimal-shell";
    flake-parts.url = "github:hercules-ci/flake-parts";
  };

  outputs =
    {
      self,
      nixpkgs,
      mk-minimal-shell,
      flake-parts,
      ...
    }:
    let
      myLib = import ./lib.nix { };
      overlay = (import ./overlay.nix { inherit mk-minimal-shell; }).overlay;
    in
    {
      mkMiniDevShell =
        argThunk:
        (myLib.forAllSystems (
          system:
          let
            requiredPkgs = import nixpkgs {
              inherit system;
              overlays = [
                mk-minimal-shell.overlay
                overlay
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

      flakeModule =
        {
          flake-parts-lib,
          lib,
          pkgs,
          config,
          system,
          ...
        }:
        {
          options.perSystem = flake-parts-lib.mkPerSystemOption (
            { config, system, ... }:
            {
              options.miniShell = lib.mkOption {
                type = lib.types.attrs;
                default = { };
                description = ''
                  An attribute set of shell arguments passed to mkCustomShell.
                  This is equivalent to the arguments you would pass to mkMiniDevShell.
                '';
              };
              config =
                let
                  shellArgs = config.miniShell;
                  extraPkgs = import nixpkgs {
                    inherit system;
                    overlays = [
                      mk-minimal-shell.overlay
                      overlay
                    ];
                  };
                  baseShell = myLib.mkCustomShell extraPkgs.mkMinimalShell shellArgs extraPkgs;
                  warningShell =
                    lib.warnIf (!(extraPkgs ? mkMinimalShell))
                      "mkMinimalShell is missing! If you've overridden pkgs, ensure that it's provided as pkgs.mkMinimalShell."
                      baseShell;
                in
                {
                  _module.args.pkgs = extraPkgs;
                  devShells.default = warningShell;
                };
            }
          );
        };

      lib = myLib;
      overlay = overlay;
    };
}
