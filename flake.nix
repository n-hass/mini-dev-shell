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
      types = import ./types.nix { lib = nixpkgs.lib; };
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
              options = {
                miniShell = types.miniShellType;
                miniShellOpts = types.miniShellOptsType;
              };
              config =
                let
                  shellArgs = config.miniShell;
                  cfg = config.miniShellOpts;
                  finalPkgs = if cfg.pkgs != null then cfg.pkgs else import nixpkgs {
                    inherit system;
                    overlays = [
                      overlay
                      mk-minimal-shell.overlay
                    ];
                  };
                  warningMkShell = userConfigArgs:
                    lib.warnIf (!(finalPkgs ? mkMinimalShell))
                      "mkMinimalShell is missing! If you've overridden pkgs, ensure that it's provided as pkgs.mkMinimalShell."
                      (myLib.mkCustomShell finalPkgs.mkMinimalShell userConfigArgs finalPkgs);
                in
                {
                  devShells.default = warningMkShell shellArgs;
                  miniShellOpts.mkShell = warningMkShell;
                  miniShellOpts.processCompose._package = if cfg.processCompose.overridePackage != null
                    then cfg.processCompose.overridePackage
                    else builtins.head ((import ./services.nix { pkgs = finalPkgs; inherit lib; }).mkProcessComposeWrappers shellArgs);
                };
            }
          );
        };

      lib = myLib;
      overlays = {
        default = overlay;
        mk-minimal-shell = mk-minimal-shell.overlay;
      };
    };
}
