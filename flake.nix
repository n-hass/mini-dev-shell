{
  description = "A flake for building development shells";

  inputs = {
    flake-utils.url = "github:numtide/flake-utils";
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
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
      mkMiniDevShell = argThunk: (flake-utils.lib.eachDefaultSystem (system: let
        requiredPkgs = import nixpkgs {
          inherit system;
          overlays = [ (mk-minimal-shell.overlay) ];
        };
        uncheckedArgs = argThunk system requiredPkgs;
        extraFlakeAttrs = uncheckedArgs.extraFlakeAttrs or {};
        args = { pkgs = requiredPkgs; } // uncheckedArgs;
        pkgs = args.pkgs;
        lib = pkgs.lib;
        shellArgs = args // { extraFlakeAttrs = null; pkgs = null; };
      in ({
        devShells =
          let
            shellHookOption = args.returnToUserShell or false;
            returnToUserShellHook = let 
              execUserShell = ''
                TARGET_SHELL=$(${pkgs.coreutils}/bin/pinky -l $USER | ${pkgs.gawk}/bin/awk '/Shell:/ {print $NF}')
                exec $TARGET_SHELL
              '';
            in {
              "" = "";
              "0" = "";
              "1" = ''
                if [ "$DIRENV_IN_ENVRC" = "1" ]; then
                  # do nothing, direnv will load a new shell
                  :
                elif [ -n "$IN_NIX_SHELL" ]; then
                  ${execUserShell}
                else
                  echo "Unknown environment loader - use direnv or 'nix develop'"
                fi
              '';
              "force" = execUserShell;
            }.${toString shellHookOption};


            generatedArgs = {
              extraUnsetEnv = [
                "returnToUserShell"
              ];
              
              shellHook = ''
                ${args.shellHook or ""}
                ${returnToUserShellHook}
              '';
            };
          in
            {
              default = let 
                result = lib.warnIf 
                  (!(pkgs ? mkMinimalShell)) 
                  "mkMinimalShell is missing! If you've overriden pkgs, ensure that it's provided as pkgs.mkMinimalShell."
                  pkgs.mkMinimalShell (lib.recursiveUpdate shellArgs generatedArgs);
              in 
                result;
            };
          } // extraFlakeAttrs
        )
      ));
      pkgs = nixpkgs;
      lib = nixpkgs.lib;
    };
}